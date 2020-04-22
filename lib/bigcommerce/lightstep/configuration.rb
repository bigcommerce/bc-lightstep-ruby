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
    # General configuration for lightstep integration
    #
    module Configuration
      VALID_CONFIG_KEYS = {
        component_name: ENV.fetch('LIGHTSTEP_COMPONENT_NAME', ''),
        controller_trace_prefix: ENV.fetch('LIGHTSTEP_CONTROLLER_PREFIX', 'controllers.'),
        access_token: ENV.fetch('LIGHTSTEP_ACCESS_TOKEN', ''),
        host: ENV.fetch('LIGHTSTEP_HOST', 'lightstep-collector.linkerd'),
        interceptors: nil,
        port: ENV.fetch('LIGHTSTEP_PORT', 4_140).to_i,
        ssl_verify_peer: ENV.fetch('LIGHTSTEP_SSL_VERIFY_PEER', 1).to_i.positive?,
        open_timeout: ENV.fetch('LIGHTSTEP_OPEN_TIMEOUT', 2).to_i,
        read_timeout: ENV.fetch('LIGHTSTEP_READ_TIMEOUT', 2).to_i,
        continue_timeout: nil,
        keep_alive_timeout: ENV.fetch('LIGHTSTEP_KEEP_ALIVE_TIMEOUT', 2).to_i,
        logger: nil,
        verbosity: ENV.fetch('LIGHTSTEP_VERBOSITY', 1).to_i,
        http1_error_code: ENV.fetch('LIGHTSTEP_HTTP1_ERROR_CODE', 500).to_i,
        http1_error_code_minimum: ENV.fetch('LIGHTSTEP_HTTP1_ERROR_CODE_MINIMUM', 500).to_i,
        max_buffered_spans: ENV.fetch('LIGHTSTEP_MAX_BUFFERED_SPANS', 1_000).to_i,
        max_log_records: ENV.fetch('LIGHTSTEP_MAX_LOG_RECORDS', 1_000).to_i,
        max_reporting_interval_seconds: ENV.fetch('LIGHTSTEP_MAX_REPORTING_INTERVAL_SECONDS', 3.0).to_f,
        redis_excluded_commands: ENV.fetch('LIGHTSTEP_REDIS_EXCLUDED_COMMANDS', 'ping').to_s.split(','),
        redis_allow_root_spans: ENV.fetch('LIGHTSTEP_REDIS_ALLOW_AS_ROOT_SPAN', 0).to_i.positive?,
        active_record: ENV.fetch('LIGHTSTEP_ACTIVE_RECORD_ENABLED', 1).to_i.positive?,
        active_record_allow_root_spans: ENV.fetch('LIGHTSTEP_ACTIVE_RECORD_ALLOW_AS_ROOT_SPAN', 0).to_i.positive?,
        active_record_span_prefix: ENV.fetch('LIGHTSTEP_ACTIVE_RECORD_SPAN_PREFIX', ''),
        enabled: ENV.fetch('LIGHTSTEP_ENABLED', 1).to_i.positive?
      }.freeze

      attr_accessor *VALID_CONFIG_KEYS.keys

      ##
      # Whenever this is extended into a class, setup the defaults
      #
      def self.extended(base)
        base.reset
      end

      ##
      # Yield self for ruby-style initialization
      #
      # @yields [Bigcommerce::Instrumentation::Configuration]
      # @return [Bigcommerce::Instrumentation::Configuration]
      #
      def configure
        reset unless @configured
        yield self
        @configured = true
      end

      ##
      # @return [Boolean]
      #
      def configured?
        @configured
      end

      ##
      # Return the current configuration options as a Hash
      #
      # @return [Hash]
      #
      def options
        opts = {}
        VALID_CONFIG_KEYS.each_key do |k|
          opts.merge!(k => send(k))
        end
        opts
      end

      ##
      # Set the default configuration onto the extended class
      #
      def reset
        VALID_CONFIG_KEYS.each do |k, v|
          send("#{k}=".to_sym, v)
        end

        default_logger = ::Logger.new(STDOUT)
        default_logger.level = ::Logger::INFO
        self.logger = defined?(Rails) ? Rails.logger : default_logger

        self.interceptors = ::Bigcommerce::Lightstep::Interceptors::Registry.new
      end

      ##
      # Automatically determine environment
      #
      # @return [String]
      #
      def environment
        if defined?(Rails)
          Rails.env
        else
          env['RACK_ENV'] || env['RAILS_ENV'] || 'development'
        end
      end

      ##
      # @return [String]
      #
      def release
        unless @release
          app_name = env.fetch('LIGHTSTEP_APP_NAME', env.fetch('NOMAD_JOB_NAME', '')).to_s
          sha = env.fetch('LIGHTSTEP_RELEASE_SHA', env.fetch('NOMAD_META_RELEASE_SHA', '')).to_s
          default_release = app_name.empty? && sha.empty? ? '' : "#{app_name}@#{sha}"
          @release = env.fetch('LIGHTSTEP_RELEASE', default_release).to_s
        end
        @release
      end

      private

      def env
        ENV
      end
    end
  end
end
