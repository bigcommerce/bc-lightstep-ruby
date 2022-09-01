# frozen_string_literal: true

require 'spec_helper'

describe Bigcommerce::Lightstep::Traceable do
  let(:service) { TestTracedService.new }
  let(:method_name) { :call }
  let(:lightstep) { ::Bigcommerce::Lightstep::Tracer.instance }
  let(:span) { instance_double(::LightStep::Span, set_tag: true) }

  before do
    allow(lightstep).to receive(:start_span).and_yield(span)
  end

  describe '#trace' do
    subject { service.call(name: name, should_fail: should_fail) }

    let(:name) { 'foo' }
    let(:should_fail) { false }

    it 'calls and passes the args to the trace block' do
      expect(span).to receive(:set_tag).with('name', name)
      subject
    end

    it 'still calls the traced method' do
      expect(subject).to eq name
    end

    it 'sets the span with the passed operation name' do
      expect(lightstep).to receive(:start_span).with('operation.call').and_yield(span)
      expect(subject).to eq name
    end

    context 'when no block is passed to trace' do
      subject { service.call_without_block(name: name, should_fail: should_fail) }

      it 'the perform method calls normally' do
        expect(span).not_to receive(:set_tag).with('traced', true)
        expect(subject).to eq name
      end
    end

    context 'when the command fails' do
      let(:should_fail) { true }

      it 'raises it normally and tags the span with the error' do
        expect(span).to receive(:set_tag).with('error', true)
        expect(span).to receive(:set_tag).with('error.message', 'oops')
        expect(span).to receive(:set_tag).with('error.class', 'StandardError')
        expect { subject }.to raise_error(StandardError, 'oops')
      end
    end

    context 'when tags are passed to trace' do
      subject { service.call_with_tags(name: name) }

      it 'sets them on the span' do
        expect(span).to receive(:set_tag).with('foo', 'bar').ordered
        expect(span).to receive(:set_tag).with('name', name).ordered
        expect(subject).to eq name
      end
    end
  end
end
