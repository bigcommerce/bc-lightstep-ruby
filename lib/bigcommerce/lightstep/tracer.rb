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
      # @param [Hash] context (Optional)
      # @param [Time] start_time (Optional)
      # @param [Hash] tags (Optional)
      # @return [LightStep::Span]
      #
      def start_span(name, context: nil, start_time: nil, tags: nil)
        tracer.enable
        context = tracer.extract(::LightStep::Tracer::FORMAT_TEXT_MAP, context || {}) unless context.is_a?(::LightStep::SpanContext)

        span = ::LightStep.start_span(name, child_of: context, start_time: start_time, tags: tags)

        parent_span = active_span
        self.active_span = span

        yield span

        span.finish
        self.active_span = parent_span
      end

      ##
      # @return [::LightStep::Span|NilClass]
      #
      def active_span
        Thread.current[:lightstep_active_span]
      end

      private

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
