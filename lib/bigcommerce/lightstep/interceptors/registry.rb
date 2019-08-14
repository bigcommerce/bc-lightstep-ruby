# frozen_string_literal: true

# Copyright (c) 2019-present, BigCommerce Pty. Ltd. All rights reserved
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
    module Interceptors
      ##
      # Thread-safe registry for interceptors
      #
      class Registry
        def initialize
          @registry = []
        end

        ##
        # Add to the thread-safe registry
        #
        # @param [Class] klass The class to add
        # @param [Hash] options A hash of options to pass into the class during initialization
        #
        def use(klass, options = {})
          registry_mutex do
            @registry << {
              klass: klass,
              options: options
            }
          end
        end

        ##
        # Intercept a trace with all interceptors
        #
        def intercept(span)
          interceptors = all
          interceptor = interceptors.pop

          return yield unless interceptor

          interceptor.call(span: span) do |yielded_span|
            if interceptors.any?
              intercept(yielded_span) { yield yielded_span }
            else
              yield yielded_span
            end
          end
        end

        ##
        # Clear the registry
        #
        def clear
          registry_mutex do
            @registry = []
          end
        end

        ##
        # @return [Integer] The number of items currently loaded
        #
        def count
          registry_mutex do
            @registry ||= []
            @registry.count
          end
        end

        ##
        # Return a list of the classes in the registry in their execution order
        #
        # @return [Array<Class>]
        #
        def list
          registry_mutex do
            @registry.map { |h| h[:klass] }
          end
        end

        ##
        # Load and return all items
        #
        # @return [Array<Object>]
        #
        def all
          is = []
          registry_mutex do
            @registry.each do |o|
              is << o[:klass].new(o[:options])
            end
          end
          is
        end

        private

        ##
        # Handle mutations to the registry in a thread-safe manner
        #
        def registry_mutex(&block)
          @registry_mutex ||= begin
            require 'monitor'
            Monitor.new
          end
          @registry_mutex.synchronize(&block)
        end
      end
    end
  end
end

require_relative 'base'
require_relative 'env'
