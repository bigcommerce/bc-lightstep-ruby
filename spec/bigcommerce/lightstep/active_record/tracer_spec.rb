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
require 'spec_helper'

class TestActiveRecordTracerCaller
  def foo
    true
  end
end

describe Bigcommerce::Lightstep::ActiveRecord::Tracer do
  let(:allow_root_spans) { false }
  let(:span_prefix) { 'auth' }
  let(:span_name) { 'mysql' }
  let(:tracer) { described_class.new(tracer: mock_tracer, allow_root_spans: allow_root_spans, span_prefix: span_prefix, span_name: span_name) }

  describe '.db_trace' do
    let(:statement) { 'SELECT * FROM accounts WHERE username = ?' }
    let(:adapter) { 'mysql' }
    let(:host) { 'redis.service' }
    let(:database) { 'test_dev' }
    let(:key) { "#{span_prefix}.#{span_name}" }
    let(:caller) { TestActiveRecordTracerCaller.new }

    subject do
      tracer.db_trace(statement: statement, adapter: adapter, host: host, database: database) do
        caller.foo
      end
    end

    context 'if the trace is successful' do
      it 'should trace the result' do
        expect(mock_tracer).to receive(:start_span).with(key).and_call_original
        expect(mock_tracer.span).to receive(:set_tag).with('db.host', host).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.type', adapter).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.name', database).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.statement', statement).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('span.kind', 'client').ordered

        expect(caller).to receive(:foo).once

        subject
      end

      context 'if allowing root spans is disabled' do
        let(:allow_root_spans) { false }

        context 'and there is no active span' do
          before do
            allow(mock_tracer).to receive(:active_span).and_return(nil)
          end

          it 'should not trace the result' do
            expect(mock_tracer).to_not receive(:start_span)
            expect(caller).to receive(:foo).once
            subject
          end
        end

        context 'and there is a root span' do
          it 'should trace the result' do
            expect(mock_tracer).to receive(:start_span).and_call_original
            expect(caller).to receive(:foo).once
            subject
          end
        end
      end

      context 'if allowing root spans is enabled' do
        let(:allow_root_spans) { true }

        context 'and there is no active span' do
          before do
            allow(mock_tracer).to receive(:active_span).and_return(nil)
          end

          it 'should trace the result' do
            expect(mock_tracer).to receive(:start_span).and_call_original
            expect(caller).to receive(:foo).once
            subject
          end
        end

        context 'and there is a root span' do
          it 'should trace the result' do
            expect(mock_tracer).to receive(:start_span).and_call_original
            expect(caller).to receive(:foo).once
            subject
          end
        end
      end
    end

    context 'if the trace raises an exception' do
      let(:exception) { StandardError.new('Oh noes') }

      before do
        allow(caller).to receive(:foo).and_raise(exception)
      end

      it 'should trace the result and add an error tag to the span' do
        expect(mock_tracer).to receive(:start_span).with(key).and_call_original
        expect(mock_tracer.span).to receive(:set_tag).with('db.host', host).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.type', adapter).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.name', database).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.statement', statement).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('span.kind', 'client').ordered

        expect(mock_tracer.span).to receive(:set_tag).with('error', true).ordered

        expect(caller).to receive(:foo).once

        expect { subject }.to raise_error(exception)
      end
    end
  end
end
