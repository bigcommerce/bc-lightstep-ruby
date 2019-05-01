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
module Bigcommerce
  module Lightstep
    module Middleware
      # Faraday middleware. It will add appropriate OT tags and trace IDs to outgoing connections done by Faraday
      class Faraday < ::Faraday::Middleware
        HTTP_ERROR_STATUS_THRESHOLD = 400
        HTTP_STATUS_REQUEST_TIMEOUT = 408
        HTTP_STATUS_INTERNAL_ERROR = 500
        HTTP_STATUS_SERVICE_UNAVAIL = 503

        OT_TAG_TRACE_ID = 'ot-tracer-traceid'
        OT_TAG_SPAN_ID = 'ot-tracer-spanid'
        OT_TAG_SAMPLED = 'ot-tracer-sampled'

        def initialize(app, service_name = nil)
          @app = app
          @service_name = (service_name || 'external').to_s
        end

        def call(request_env)
          uri = uri_from_env(request_env)
          tracer = ::Bigcommerce::Lightstep::Tracer.instance

          tracer.start_span(service_key, context: request_env[:request_headers]) do |span|
            span.set_tag('http.url', uri.to_s.split('?').first)
            span.set_tag('http.method', request_env[:method].to_s.downcase)
            span.set_tag('http.external-service', true)

            inject_ot_tags!(request_env, span)

            begin
              response = @app.call(request_env).on_complete do |response_env|
                span.set_tag('http.status_code', response_env[:status].to_s)
                span.set_tag('error', true) if response_env[:status].to_i >= HTTP_ERROR_STATUS_THRESHOLD
                response_env
              end
            rescue ::Net::ReadTimeout
              span.set_tag('error', true)
              span.set_tag('http.status_code', HTTP_STATUS_REQUEST_TIMEOUT)
              raise
            rescue ::Faraday::ConnectionFailed
              span.set_tag('error', true)
              span.set_tag('http.status_code', HTTP_STATUS_SERVICE_UNAVAIL)
              raise
            rescue ::Faraday::ClientError
              span.set_tag('error', true)
              span.set_tag('http.status_code', HTTP_STATUS_INTERNAL_ERROR)
              raise
            end

            response
          end
        end

        private

        ##
        # @param [Hash] request_env
        # @param [::LightStep::Span] span
        #
        def inject_ot_tags!(request_env, span)
          request_env[:request_headers].merge!(
            OT_TAG_TRACE_ID => span.context.trace_id.to_s,
            OT_TAG_SPAN_ID => span.context.id.to_s,
            OT_TAG_SAMPLED => 'true'
          )
        end

        ##
        # Handle either a URI object (passed by Faraday v0.8.x in testing), or something string-izable
        #
        # @param [Hash] env
        # @return [URI::HTTP]
        #
        def uri_from_env(env)
          env[:url].respond_to?(:host) ? env[:url] : URI.parse(env[:url].to_s)
        end

        ##
        # @param [URI::HTTP] uri
        # @return [String]
        #
        def path_key_for_uri(uri)
          uri.path.tr('/', '_').reverse.chomp('_').reverse.chomp
        end

        ##
        # @return [String]
        #
        def service_key
          @service_name.to_s.downcase.tr('-', '_').tr('.', '_')
        end
      end
    end
  end
end
