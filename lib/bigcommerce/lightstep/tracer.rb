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
      private

      def initialize; end

      public

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
        # enable the tracer (for fork support)
        tracer.enable

        # find the currently active span
        last_active_span = active_span

        # determine who is the actual parent span
        current_parent = determine_parent(context: context)

        # create new span
        span = ::LightStep.start_span(name, child_of: current_parent, start_time: start_time, tags: tags)

        # set it as the active span
        self.active_span = span

        # run the process
        result = yield span

        # finish this span if the reporter is initialized
        span.finish if reporter_initialized?

        # now set back the parent as the active span
        self.active_span = last_active_span

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

      private

      ##
      # Determine the active parent
      #
      # @param [Hash|::LightStep::SpanContext] context
      # @return [::LightStep::SpanContext]
      #
      def determine_parent(context:)
        # first attempt to find parent from args, if not, use carrier (headers) to lookup parent
        current_parent = context.is_a?(::LightStep::SpanContext) ? context : tracer.extract(::LightStep::Tracer::FORMAT_TEXT_MAP, context || {})
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
    end
  end
end
