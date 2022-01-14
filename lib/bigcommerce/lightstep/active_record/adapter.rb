# frozen_string_literal: true

# Copyright (c) 2020-present, BigCommerce Pty. Ltd. All rights reserved
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
    module ActiveRecord
      ##
      # Patches mysql and ActiveRecord to allow for mysql span tracing
      #
      module Adapter
        extend ::ActiveSupport::Concern

        ##
        # Patch ActiveRecord to enable mysql span traces
        #
        def self.patch
          return unless enabled?

          # rubocop:disable Lint/SendWithMixinArgument
          ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:include, ::Bigcommerce::Lightstep::ActiveRecord::Adapter)
          # rubocop:enable Lint/SendWithMixinArgument
        end

        ##
        # Note: we only support patching mysql2 gem at this point
        #
        # @return [Boolean]
        #
        def self.enabled?
          defined?(::ActiveRecord) && ::Bigcommerce::Lightstep.active_record && ::ActiveRecord::Base.connection_config[:adapter].to_s.casecmp('mysql2').zero?
        rescue StandardError => e
          ::Bigcommerce::Lightstep.logger&.warn "Failed to determine ActiveRecord database adapter in bc-lightstep-ruby initializer: #{e.message}"
          false
        end

        ##
        # @param [String] sql The raw sql query
        # @param [String] name The type of sql query
        #
        def execute_with_inst(sql, name = 'SQL')
          # bail out early if not enabled. This should not get here, but is provided as a failsafe.
          return execute_without_inst(sql, name) unless ::Bigcommerce::Lightstep.active_record

          sanitized_sql = lightstep_sanitize_sql(sql)
          name = 'QUERY' if name.to_s.strip.empty?

          # we dont need to track all sql
          return execute_without_inst(sql, name) if lightstep_skip_tracing?(name, sanitized_sql)

          lightstep_tracer.db_trace(
            statement: sanitized_sql,
            host: @config[:host],
            adapter: @config[:adapter],
            database: @config[:database]
          ) do
            execute_without_inst(sql, name)
          end
        end

        ##
        # Sanitize the sql for safe logging
        #
        # @param [String]
        # @return [String]
        #
        def lightstep_sanitize_sql(sql)
          sql.to_s.gsub(lightstep_sanitization_regexp, '?').tr("\n", ' ').to_s
        end

        ##
        # @return [Regexp]
        #
        def lightstep_sanitization_regexp
          @lightstep_sanitization_regexp ||= ::Regexp.new('(\'[\s\S][^\']*\'|\d*\.\d+|\d+|NULL)', ::Regexp::IGNORECASE)
        end

        ##
        # Filter out sql queries from tracing we don't care about
        #
        # @param [String] name
        # @param [String] sql
        # @return [Boolean]
        def lightstep_skip_tracing?(name, sql)
          name.empty? || sql.empty? || sql.include?('COMMIT') || sql.include?('SCHEMA') || sql.include?('SHOW FULL FIELDS')
        end

        ##
        # @return [::Bigcommerce::Lightstep::ActiveRecord::Tracer]
        #
        def lightstep_tracer
          @lightstep_tracer ||= ::Bigcommerce::Lightstep::ActiveRecord::Tracer.new
        end

        included do
          if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::MAJOR > 3
            alias_method :execute_without_inst, :execute
            alias_method :execute, :execute_with_inst
          end
        end
      end
    end
  end
end
