# frozen_string_literal: true

begin
  require 'rspec/core'
  require 'rspec/expectations'
  BC_LIGHTSTEP_RSPEC_NAMESPACE = RSpec
  BC_LIGHTSTEP_RSPEC_RUNNER = RSpec
rescue LoadError # old rspec compat
  require 'spec'
  BC_LIGHTSTEP_RSPEC_NAMESPACE = Spec
  BC_LIGHTSTEP_RSPEC_RUNNER = Spec::Runner
end

module Bigcommerce
  module Lightstep
    ##
    # RSpec helper for lightstep traces
    #
    module RspecHelpers
      def lightstep_tracer
        ::Bigcommerce::Lightstep::Tracer.instance
      end
    end
  end
end

##
# Usage:
#   expect { my_code_here }.to create_a_lightstep_span(name: 'my-span-name', tags: { tag_one: 'value-here' })
#
BC_LIGHTSTEP_RSPEC_NAMESPACE::Matchers.define :create_a_lightstep_span do |opts|
  match(notify_expectation_failures: true) do |proc|
    span_name = opts.fetch(:name)
    lightstep_span = ::LightStep::Span.new(
      tracer: ::Bigcommerce::Lightstep::Tracer.instance,
      operation_name: span_name,
      max_log_records: 0,
      start_micros: 0
    )
    expect(::Bigcommerce::Lightstep::Tracer.instance).to receive(:start_span).with(span_name).and_yield(lightstep_span).ordered
    opts.fetch(:tags, {}).each do |key, value|
      expect(lightstep_span).to receive(:set_tag).with(key.to_s, value)
    end
    proc.call
  end
  supports_block_expectations
end

BC_LIGHTSTEP_RSPEC_RUNNER.configure do |config|
  config.include Bigcommerce::Lightstep::RspecHelpers
  config.before do
    # provide a dummy span for noop calls
    lightstep_span = ::LightStep::Span.new(
      tracer: ::Bigcommerce::Lightstep::Tracer.instance,
      operation_name: 'default',
      max_log_records: 0,
      start_micros: 0
    )
    allow(::Bigcommerce::Lightstep::Tracer.instance).to receive(:start_span).and_yield(lightstep_span)
  end
end
