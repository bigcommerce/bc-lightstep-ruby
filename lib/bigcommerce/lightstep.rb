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
require_relative 'lightstep/version'
require_relative 'lightstep/errors'
require_relative 'lightstep/interceptors/registry'
require_relative 'lightstep/interceptors/context'
require_relative 'lightstep/configuration'
require_relative 'lightstep/tracer'
require_relative 'lightstep/transport_factory'
require_relative 'lightstep/transport'
require_relative 'lightstep/rails_controller_instrumentation'
require_relative 'lightstep/middleware/faraday'
require_relative 'lightstep/active_record/tracer'
require_relative 'lightstep/active_record/adapter'
require_relative 'lightstep/redis/tracer'

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
