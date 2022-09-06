# frozen_string_literal: true

module Bigcommerce
  module Lightstep
    ##
    # Module for adding drop-in tracing to any method. Example usage:
    #
    # ```ruby
    # class MyService
    #   include ::Bigcommerce::Lightstep::Traceable
    #
    #   trace :call, 'operation.do-my-thing' do |span, product, options|
    #     span.set_tag('store_id', request.store_id)
    #   end
    #   # or, with no block:
    #   trace :call, 'operation.do-my-thing'
    #
    #   def call(product:, options:)
    #     # ...
    #   end
    # end
    # ```
    #
    module Traceable
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Extend the class with the tracing methods.
      #
      module ClassMethods
        ##
        # Trace the perform method for the command with the given operation name as the span name
        #
        # @param [Symbol] method_name The method to trace
        # @param [String] operation_name The name to give the span
        # @param [Hash] tags A key/value hash of tags to set on the created span
        # @param [Proc] span_block A block to yield before calling perform; useful for setting tags on the outer span
        #
        def trace(method_name, operation_name, tags: nil, &span_block)
          method_name = method_name.to_sym
          mod = Module.new
          mod.define_method(method_name) do |*args, &block|
            tracer = ::Bigcommerce::Lightstep::Tracer.instance
            tracer.start_span(operation_name) do |span|
              tags&.each { |k, v| span.set_tag(k.to_s, v) }
              begin
                arg1 = args.first
                # method has keyword argument signature (or single-hash positional argument)
                if arg1.is_a?(Hash) && args.count == 1
                  # add span as a kwarg
                  span_block&.send(:call, **arg1.merge(span: span))
                  super(**arg1, &block)
                else
                  # method has positional argument signature, so just add span to front
                  span_block&.send(:call, *([span] + args))
                  super(*args, &block)
                end
              rescue StandardError => e
                span.set_tag('error', true)
                span.set_tag('error.message', e.message)
                span.set_tag('error.class', e.class.to_s)
                raise
              end
            end
          end
          prepend(mod)
        end
      end
    end
  end
end
