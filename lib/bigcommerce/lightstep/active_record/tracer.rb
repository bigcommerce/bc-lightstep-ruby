# frozen_string_literal: true

# Copyright (c) 2020-present, BigCommerce Pty. Ltd. All rights reserved
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
module Bigcommerce
  module Lightstep
    module ActiveRecord
      ##
      # Tracer adapter for ActiveRecord
      #
      class Tracer
        ##
        # @param [Bigcommerce::Lightstep::Tracer] tracer
        # @param [String] span_prefix
        # @param [Boolean] allow_root_spans
        # @param [String] span_name
        #
        def initialize(tracer: nil, span_prefix: nil, span_name: nil, allow_root_spans: nil)
          @tracer = tracer || ::Bigcommerce::Lightstep::Tracer.instance
          @span_prefix = span_prefix || ::Bigcommerce::Lightstep.active_record_span_prefix
          @span_name = span_name || 'mysql'
          @allow_root_spans = allow_root_spans.nil? ? ::Bigcommerce::Lightstep.active_record_allow_root_spans : allow_root_spans
        end

        ##
        # Trace a DB call
        #
        # @param [String] statement
        # @param [String] host
        # @param [String] adapter
        # @param [String] database
        #
        def db_trace(statement:, host:, adapter:, database:)
          return yield unless @tracer

          # skip if not allowing root spans and there is no active span
          return yield if !@allow_root_spans && !active_span?

          @tracer.start_span(key) do |span|
            span.set_tag('db.host', host.to_s)
            span.set_tag('db.type', adapter.to_s)
            span.set_tag('db.name', database.to_s)
            span.set_tag('db.statement', statement.to_s)
            span.set_tag('span.kind', 'client')
            begin
              yield
            rescue StandardError => _e
              span.set_tag('error', true)
              raise # re-raise the error
            end
          end
        end

        ##
        # @return [String]
        #
        def key
          @span_prefix.to_s.empty? ? 'mysql' : "#{@span_prefix}.mysql"
        end

        ##
        # @return [Boolean]
        #
        def active_span?
          @tracer.respond_to?(:active_span) && @tracer.active_span
        end
      end
    end
  end
end
