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
        component_name: '',
        controller_trace_prefix: 'controllers.',
        access_token: '',
        host: 'lightstep-collector.linkerd',
        interceptors: nil,
        port: 4140,
        ssl_verify_peer: true,
        open_timeout: 20,
        read_timeout: 20,
        continue_timeout: nil,
        keep_alive_timeout: 2,
        logger: nil,
        verbosity: 1,
        http1_error_code: 500,
        http1_error_code_minimum: 500,
        max_buffered_spans: 1_000,
        max_log_records: 1_000,
        max_reporting_interval_seconds: 3.0,
        redis_excluded_commands: %w[ping],
        redis_allow_root_spans: false,
        enabled: true
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
        self.component_name = ENV.fetch('LIGHTSTEP_COMPONENT_NAME', '')
        self.access_token = ENV.fetch('LIGHTSTEP_ACCESS_TOKEN', '')
        self.host = ENV.fetch('LIGHTSTEP_HOST', 'lightstep-collector.linkerd')
        self.port = ENV.fetch('LIGHTSTEP_PORT', 4140).to_i
        self.ssl_verify_peer = ENV.fetch('LIGHTSTEP_SSL_VERIFY_PEER', true)

        self.max_buffered_spans = ENV.fetch('LIGHTSTEP_MAX_BUFFERED_SPANS', 1_000).to_i
        self.max_log_records = ENV.fetch('LIGHTSTEP_MAX_LOG_RECORDS', 1_000).to_i
        self.max_reporting_interval_seconds = ENV.fetch('LIGHTSTEP_MAX_REPORTING_INTERVAL_SECONDS', 3.0).to_f

        default_logger = ::Logger.new(STDOUT)
        default_logger.level = ::Logger::INFO
        self.logger = defined?(Rails) ? Rails.logger : default_logger
        self.verbosity = ENV.fetch('LIGHTSTEP_VERBOSITY', 1).to_i

        self.enabled = ENV.fetch('LIGHTSTEP_ENABLED', 1).to_i.positive?
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
