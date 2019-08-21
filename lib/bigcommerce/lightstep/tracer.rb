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
    ##
    # Global tracer
    #
    class Tracer
      include Singleton

      ##
      # Start a new span
      #
      # @param [String] name The operation name for the Span
      # @param [Hash|::LightStep::SpanContext] context (Optional)
      # @param [Time] start_time (Optional)
      # @param [Hash] tags (Optional)
      #
      def start_span(name, context: nil, start_time: nil, tags: nil)
        if enabled?
          # enable the tracer (for fork support)
          tracer.enable
        elsif tracer&.enabled?
          # We are not enabled and the tracer is currently on
          # https://github.com/lightstep/lightstep-tracer-ruby/blob/master/lib/lightstep/tracer.rb#L129-L130
          # we have to set this through instance_variable_set because of a bug in the core lightstep gem which
          # assumes the presence of a reporter, which happens in the initializer, which may not be called
          # because the reporter attempts to flush spans on initialization (which is bad if lightstep isn't
          # present)
          tracer.instance_variable_set(:@enabled, false)
        end

        # find the currently active span
        last_active_span = active_span

        # determine who is the actual parent span
        current_parent = determine_parent(context: context)

        # create new span
        span = ::LightStep.start_span(name, child_of: current_parent, start_time: start_time, tags: tags)

        mark_root_span(span) if active_span.nil?

        # set it as the active span
        self.active_span = span

        # run the process
        result = nil
        begin
          build_context.intercept(span) do |inner_span|
            result = yield inner_span
          end
        rescue StandardError
          span.set_tag('error', true)
          raise
        ensure
          # finish this span if the reporter is initialized
          span.finish if enabled? && reporter_initialized?

          # now set back the parent as the active span
          self.active_span = last_active_span
        end

        # return result
        result
      end

      ##
      # Return the active span
      #
      # @return [::LightStep::Span|NilClass]
      #
      def active_span
        Thread.current[:lightstep_active_span]
      end

      ##
      # Clear the active span
      #
      def clear_active_span!
        Thread.current[:lightstep_active_span] = nil
      end

      ##
      # @return [Boolean]
      #
      def reporter_initialized?
        tracer.instance_variable_defined?(:@reporter) && !tracer.instance_variable_get(:@reporter).nil?
      end

      ##
      # @return [Boolean]
      #
      def enabled?
        Bigcommerce::Lightstep.enabled
      end

      private

      ##
      # @return [::Bigcommerce::Lightstep::Interceptors::Context]
      #
      def build_context
        ::Bigcommerce::Lightstep::Interceptors::Context.new
      end

      ##
      # Determine the active parent
      #
      # @param [Hash|::LightStep::SpanContext] context
      # @return [::LightStep::SpanContext]
      #
      def determine_parent(context:)
        # first attempt to find parent from args, if not, use carrier (headers) to lookup parent
        # 1 = FORMAT_TEXT_MAP (this constant is removed in future lightstep versions)
        current_parent = context.is_a?(::LightStep::SpanContext) ? context : tracer.extract(1, context || {})
        # if no passed in parent, use the active thread parent
        current_parent = active_span if current_parent.nil?
        current_parent
      end

      ##
      # @param [::LightStep::Span] span
      #
      def active_span=(span)
        Thread.current[:lightstep_active_span] = span
      end

      ##
      # @return [::LightStep::Tracer]
      #
      def tracer
        LightStep.instance
      end

      ##
      # Because LightStep doesn't allow changing the span return class, or adding any arbitrary attributes, we need
      # to do this here to mark what is the "root" span in a service.
      #
      def mark_root_span(span)
        span.instance_variable_set(:@root_span, true)
      end
    end
  end
end
