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
          'nomad.task_name': 'NOMAD_TASK_NAME',
          'provider.region': 'NOMAD_REGION',
          'provider.datacenter': 'NOMAD_DC'
        }.freeze

        ##
        # @param [Hash] keys A hash of span->env key mappings
        # @param [ENV] env The ENV class to get variables from
        # @param [Array<Symbol>] presets Specify presets that automatically setup keys
        #
        def initialize(keys: nil, env: nil, presets: [])
          @keys = keys || {}
          @presets = presets || []
          @env = env || ENV
          augment_keys_with_presets!
        end

        ##
        # @param [::LightStep::Span] span
        #
        def call(span:)
          @keys.each do |span_key, env_key|
            value = @env.fetch(env_key.to_s, nil)
            span.set_tag(span_key.to_s.downcase.tr('-', '_').strip, value.nil? ? '' : value)
          end

          yield span
        end

        private

        ##
        # Augment keys based on presets
        #
        def augment_keys_with_presets!
          @presets.each do |preset|
            case preset
            when :nomad
              @keys.merge!(PRESET_NOMAD)
            end
          end
        end
      end
    end
  end
end
