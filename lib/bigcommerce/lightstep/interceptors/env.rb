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
    module Interceptors
      ##
      # Hydrates span tags with specified ENV vars
      #
      class Env < Base
        PRESET_NOMAD = {
          'container.cpu': 'NOMAD_CPU_LIMIT',
          'container.mem': 'NOMAD_MEMORY_LIMIT',
          'git.sha': 'NOMAD_META_SHA',
          'nomad.node.id': 'NOMAD_NODE_ID',
          'nomad.node.name': 'NOMAD_NODE_NAME',
          'nomad.task_name': 'NOMAD_TASK_NAME',
          'provider.region': 'NOMAD_REGION',
          'provider.datacenter': 'NOMAD_DC'
        }.freeze

        PRESET_HOSTNAME = {
          hostname: 'HOSTNAME'
        }.freeze

        ##
        # @param [Hash] keys A hash of span->env key mappings
        # @param [ENV] env The ENV class to get variables from
        # @param [Array<Symbol>] presets Specify presets that automatically setup keys
        #
        def initialize(keys: nil, env: nil, presets: [])
          super()
          @keys = keys || {}
          @presets = presets || []
          @env = env || ENV
          augment_keys_with_presets!
          collect_values!
        end

        ##
        # @param [::LightStep::Span] span
        #
        def call(span:)
          return yield span unless root_span?(span)

          value_mutex do
            @values.each do |span_key, value|
              span.set_tag(span_key, value)
            end
          end

          yield span
        end

        private

        def root_span?(span)
          span.instance_variable_get(:@root_span) == true
        end

        ##
        # Pre-collect values at start
        #
        def collect_values!
          value_mutex do
            @values = {}
            @keys.each do |span_key, env_key|
              value = @env.fetch(env_key.to_s, nil)
              value = '' if value.nil?

              @values[span_key.to_s.downcase.tr('-', '_').strip] = value
            end
            @values
          end
        end

        ##
        # Augment keys based on presets
        #
        def augment_keys_with_presets!
          @presets.each do |preset|
            case preset
            when :hostname
              @keys.merge!(PRESET_HOSTNAME)
            when :nomad
              @keys.merge!(PRESET_NOMAD)
            end
          end
        end

        ##
        # Handle access to values in a thread-safe manner
        #
        def value_mutex(&)
          @value_mutex ||= begin
            require 'monitor'
            Monitor.new
          end
          @value_mutex.synchronize(&)
        end
      end
    end
  end
end
