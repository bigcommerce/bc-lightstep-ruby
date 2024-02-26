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
    module Redis
      ##
      # Instrumentation wrapper for Redis
      #
      module Wrapper
        class << self
          def patch
            require 'redis' # thread and fork safety

            # do not patch Redis 5.0.0 or later, move to OpenTelemetry gems instead
            return false unless defined?(::Redis) && ::Redis::VERSION < '5'

            return if @wrapped

            wrap unless @wrapped
            @wrapped = true
          rescue ::LoadError => _e
            @wrapped = false
            # noop
          end

          private

          def wrap
            raise ::LoadError, 'Redis not loaded' unless defined?(::Redis::Client)

            ::Redis::Client.class_eval do
              alias_method :call_original, :call
              alias_method :call_pipeline_original, :call_pipeline

              def call(command, &block)
                return call_original(command) unless bc_lightstep_tracer

                bc_lightstep_tracer.trace(
                  key: "redis.#{command[0]}",
                  statement: command.join(' '),
                  instance: db,
                  host: host,
                  port: port
                ) do
                  call_original(command, &block)
                end
              end

              def call_pipeline(pipeline)
                return call_pipeline_original(pipeline) unless bc_lightstep_tracer

                commands = pipeline.try(:commands) || []
                bc_lightstep_tracer.trace(
                  key: 'redis.pipelined',
                  statement: commands.empty? ? '' : commands.map { |arr| arr.join(' ') }.join(', '),
                  instance: db,
                  host: host,
                  port: port
                ) do
                  call_pipeline_original(pipeline)
                end
              end

              ##
              # @return [::Bigcommerce::Lightstep::Redis::Tracer]
              #
              def bc_lightstep_tracer
                @bc_lightstep_tracer ||= ::Bigcommerce::Lightstep::Redis::Tracer.new
              end
            end
          end
        end
      end
    end
  end
end
