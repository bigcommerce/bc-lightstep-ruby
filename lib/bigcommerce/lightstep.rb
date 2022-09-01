# frozen_string_literal: true

# Copyright (c) 2018-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'lightstep'
require 'faraday'
require 'active_support/concern'

# use Zeitwerk to lazily autoload all the files in the lib directory
require 'zeitwerk'
loader = ::Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, '.rb')
loader.inflector = ::Zeitwerk::GemInflector.new(__FILE__)
loader.ignore("#{__dir__}/lightstep/rspec.rb")
loader.ignore("#{File.dirname(__dir__)}/bc-lightstep-ruby.rb")
loader.push_dir(File.dirname(__dir__))
loader.setup

##
# Main base module
#
module Bigcommerce
  ##
  # Lightstep module
  #
  module Lightstep
    extend Configuration

    ##
    # Start the global tracer and configure LightStep
    #
    # @param [String] component_name
    # @param [::Bigcommerce::Lightstep::TransportFactory] transport_factory
    #
    def self.start(component_name: nil, transport_factory: nil)
      component_name ||= ::Bigcommerce::Lightstep.component_name
      transport_factory ||= ::Bigcommerce::Lightstep::TransportFactory.new
      ::LightStep.logger = logger
      tags = {}
      tags['service.version'] = ::Bigcommerce::Lightstep.release unless ::Bigcommerce::Lightstep.release.empty?
      ::LightStep.configure(
        component_name: component_name,
        transport: transport_factory.build,
        tags: tags
      )
      ::LightStep.instance.max_span_records = ::Bigcommerce::Lightstep.max_buffered_spans
      ::LightStep.instance.max_log_records = ::Bigcommerce::Lightstep.max_log_records
      ::LightStep.instance.report_period_seconds = ::Bigcommerce::Lightstep.max_reporting_interval_seconds

      return unless ::Bigcommerce::Lightstep.enabled

      ::Bigcommerce::Lightstep::Redis::Wrapper.patch
      ::Bigcommerce::Lightstep::ActiveRecord::Adapter.patch
    end
  end
end
