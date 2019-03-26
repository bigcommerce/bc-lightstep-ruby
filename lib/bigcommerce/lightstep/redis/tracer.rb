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
require_relative 'wrapper'

module Bigcommerce
  module Lightstep
    module Redis
      ##
      # Middleware tracer for Redis clients
      #
      class Tracer
        attr_accessor :tracer

        ##
        # @param [Bigcommerce::Lightstep::Tracer] tracer
        # @param [Array<String>] excluded_commands
        # @param [Boolean] allow_root_spans
        #
        def initialize(
          tracer: nil,
          excluded_commands: nil,
          allow_root_spans: nil
        )
          @tracer = tracer || ::Bigcommerce::Lightstep::Tracer.instance
          @excluded_commands = excluded_commands || ::Bigcommerce::Lightstep.redis_excluded_commands
          @allow_root_spans = allow_root_spans.nil? ? ::Bigcommerce::Lightstep.redis_allow_root_spans : allow_root_spans
        end

        ##
        # @param [String] key
        # @param [String] statement
        # @param [String] instance
        # @param [String] host
        # @param [Integer] port
        #
        def trace(key:, statement:, instance:, host:, port:)
          return yield unless @tracer

          # only take the command, not any arguments
          command = statement.to_s.split(' ').first

          # skip excluded commands
          return yield if excluded?(command.to_s)

          # skip if not allowing root spans and there is no active span
          return yield if !@allow_root_spans && !active_span?

          tags = {
            'db.type' => 'redis',
            'db.statement' => command,
            'db.instance' => instance,
            'db.host' => "redis://#{host}:#{port}",
            'span.kind' => 'client'
          }

          @tracer.start_span(key) do |span|
            tags.each do |k, v|
              span.set_tag(k, v)
            end
            begin
              resp = yield
            rescue StandardError => _
              span.set_tag('error', true)
              raise # re-raise the error
            end
            resp
          end
        end

        ##
        # @param [String] command
        # @return [Boolean]
        #
        def excluded?(command)
          @excluded_commands.include?(command.to_s)
        end

        ##
        # @return [Boolean]
        #
        def active_span?
          tracer.respond_to?(:active_span) && tracer.active_span
        end
      end
    end
  end
end
