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
require 'net/http'
require 'lightstep/transport/base'
require 'logger'

module Bigcommerce
  module Lightstep
    # This is a transport that sends reports via HTTP in JSON format.
    # It is thread-safe, however it is *not* fork-safe. When forking, all items
    # in the queue will be copied and sent in duplicate.
    class Transport < ::LightStep::Transport::Base
      class InvalidAccessTokenError < StandardError; end

      ENCRYPTION_TLS = 'tls'
      ENCRYPTION_NONE = 'none'
      HEADER_ACCESS_TOKEN = 'LightStep-Access-Token'
      LIGHTSTEP_HOST = 'collector.lightstep.com'
      LIGHTSTEP_PORT = 443
      REPORTS_API_ENDPOINT = '/api/v0/reports'

      DEFAULT_OPEN_TIMEOUT = 20
      DEFAULT_READ_TIMEOUT = 20
      DEFAULT_KEEPALIVE_TIMEOUT = 2
      DEFAULT_SSL_PORT = 443

      ##
      # Verbosity levels for the transport
      #
      class Verbosity
        FATAL = 0
        ERROR = 1
        WARN = 2
        INFO = 3
        DEBUG = 4
      end

      # Initialize the transport
      # @param host [String] host of the domain to the endpoind to push data
      # @param port [Numeric] port on which to connect
      # @param verbose [Numeric] verbosity level. Right now 0-3 are supported
      # @param encryption [ENCRYPTION_TLS, ENCRYPTION_NONE] kind of encryption to use
      # @param ssl_verify_peer [Boolean]
      # @param access_token [String] access token for LightStep server
      # @return [Transport]
      def initialize(
        access_token:,
        host: nil,
        port: nil,
        verbose: nil,
        encryption: nil,
        ssl_verify_peer: true,
        ssl_port: nil,
        open_timeout: nil,
        read_timeout: nil,
        continue_timeout: nil,
        keep_alive_timeout: nil,
        logger: nil
      )
        @host = host | LIGHTSTEP_HOST
        @port = port || LIGHTSTEP_PORT
        @verbose = verbose || Verbosity::FATAL
        @encryption = encryption || ENCRYPTION_TLS
        @ssl_verify_peer = ssl_verify_peer
        @ssl_port = (ssl_port || DEFAULT_SSL_PORT).to_i
        @open_timeout = (open_timeout || DEFAULT_OPEN_TIMEOUT).to_i
        @read_timeout = (read_timeout || DEFAULT_READ_TIMEOUT).to_i
        @continue_timeout = continue_timeout
        @keep_alive_timeout = (keep_alive_timeout || DEFAULT_KEEPALIVE_TIMEOUT).to_i
        @access_token = access_token.to_s

        default_logger = ::Logger.new($stdout)
        default_logger.level = ::Logger::INFO
        @logger = logger || default_logger
        super()
      end

      ##
      # Queue a report for sending
      #
      # @param [Hash] report
      # @return [NilClass]
      #
      def report(report)
        @logger.info report if @verbose >= Verbosity::INFO

        req = build_request(report)
        res = connection.request(req)

        @logger.info res.to_s if @verbose >= Verbosity::INFO

        nil
      end

      private

      ##
      # @param [Hash] report
      # @return [Net::HTTP::Post]
      #
      def build_request(report)
        req = Net::HTTP::Post.new(REPORTS_API_ENDPOINT)
        req[HEADER_ACCESS_TOKEN] = @access_token unless @access_token.to_s.empty?
        req['Content-Type'] = 'application/json'
        req['Connection'] = 'keep-alive'
        req.body = report.to_json
        req
      end

      ##
      # @return [Net::HTTP]
      #
      def connection
        unless @connection
          @connection = ::Net::HTTP.new(@host, @port)
          if @port == @ssl_port
            @connection.use_ssl = @encryption == ENCRYPTION_TLS
            @connection.verify_mode = ::OpenSSL::SSL::VERIFY_NONE unless @ssl_verify_peer
          end
          @connection.open_timeout = @open_timeout
          @connection.read_timeout = @read_timeout
          @connection.continue_timeout = @continue_timeout
          @connection.keep_alive_timeout = @keep_alive_timeout
        end
        @connection
      end
    end
  end
end
