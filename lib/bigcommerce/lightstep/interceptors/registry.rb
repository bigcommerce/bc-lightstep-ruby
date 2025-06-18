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
        # @param [Class|Object] klass The class to add or object to register.
        # @param [Hash] options (Optional) A hash of options to pass into the class during initialization
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
            @registry.map do |h|
              h[:klass].instance_of?(Class) ? h[:klass] : h[:klass].class
            end
          end
        end

        ##
        # Load and return all items
        #
        # @return [Array<Object>]
        #
        def all
          registry_mutex do
            @registry.map do |o|
              o[:klass].is_a?(Class) ? o[:klass].new(o[:options]) : o[:klass]
            end
          end
        end

        private

        ##
        # Handle mutations to the registry in a thread-safe manner
        #
        def registry_mutex(&)
          @registry_mutex ||= begin
            require 'monitor'
            Monitor.new
          end
          @registry_mutex.synchronize(&)
        end
      end
    end
  end
end

require_relative 'base'
require_relative 'env'
