module Bigcommerce
  module Lightstep
    ##
    # Helper module that can be included into Rails controllers to automatically instrument them with LightStep
    #
    module RailsControllerInstrumentation
      def self.included(base)
        base.send(:around_action, :lightstep_trace)
      end

      protected

      ##
      # Trace the controller method
      #
      def lightstep_trace
        key = "#{controller_name}.#{action_name}"
        headers = request.headers.to_h.except('HTTP_COOKIE')
        tracer = ::Bigcommerce::Lightstep::Tracer.instance
        result = tracer.start_span(key, context: headers) do |span|
          span.set_tag('controller.name', controller_name)
          span.set_tag('action.name', action_name)
          yield
        end
        tracer.clear_active_span!
        result
      end
    end
  end
end
