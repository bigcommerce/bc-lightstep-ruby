module Bigcommerce
  module Lightstep
    ##
    # Helper module that can be included into Rails controllers to automatically instrument them with LightStep
    #
    module RailsControllerInstrumentation
      LIGHTSTEP_H1_ERROR_CODE = 500
      LIGHTSTEP_H1_ERROR_CODE_MIN = 400

      def self.included(base)
        base.send(:around_action, :lightstep_trace)
      end

      protected

      ##
      # Trace the controller method
      #
      def lightstep_trace
        prefix = ::Bigcommerce::Lightstep.controller_trace_prefix
        key = "#{prefix}#{controller_name}.#{action_name}"
        headers = request.headers.to_h.except('HTTP_COOKIE')
        tracer = ::Bigcommerce::Lightstep::Tracer.instance
        result = tracer.start_span(key, context: headers) do |span|
          span.set_tag('controller.name', controller_name)
          span.set_tag('action.name', action_name)
          span.set_tag('http.url', request.original_url.split('?').first)
          span.set_tag('http.method', request.method)
          span.set_tag('http.content_type', request.format)
          span.set_tag('http.host', request.host)
          begin
            resp = yield
          rescue StandardError => _
            span.set_tag('error', true)
            span.set_tag('http.status_code', LIGHTSTEP_H1_ERROR_CODE)
            tracer.clear_active_span!
            span.finish
            raise # re-raise the error
          end
          span.set_tag('http.status_code', response.status)
          # 400+ HTTP status codes are errors: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
          span.set_tag('error', true) if response.status >= LIGHTSTEP_H1_ERROR_CODE_MIN
          resp
        end
        tracer.clear_active_span!
        result
      end
    end
  end
end
