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
require 'spec_helper'

class TestRedisTracerCaller
  def foo
    true
  end
end

describe Bigcommerce::Lightstep::Redis::Tracer do
  let(:tracer) { described_class.new }

  before do
    allow(::Bigcommerce::Lightstep::Tracer).to receive(:instance).and_return(mock_tracer)
  end

  describe '.trace' do
    let(:key) { 'redis.get' }
    let(:statement) { 'get key123' }
    let(:instance) { 1 }
    let(:host) { 'redis.service' }
    let(:port) { 6379 }
    let(:caller) { TestRedisTracerCaller.new }

    subject do
      tracer.trace(key: key, statement: statement, instance: instance, host: host, port: port) do
        caller.foo
      end
    end

    context 'if the trace is successful' do
      it 'should trace the result' do
        expect(mock_tracer).to receive(:start_span).with(key).and_call_original
        expect(mock_tracer.span).to receive(:set_tag).with('db.type', 'redis').ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.statement', 'get').ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.instance', instance).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.host', "redis://#{host}:#{port}").ordered
        expect(mock_tracer.span).to receive(:set_tag).with('span.kind', 'client').ordered

        expect(caller).to receive(:foo).once

        subject
      end
    end

    context 'if the trace raises an exception' do
      let(:exception) { StandardError.new('Oh noes') }

      before do
        allow(caller).to receive(:foo).and_raise(exception)
      end

      it 'should trace the result and add an error tag to the span' do
        expect(mock_tracer).to receive(:start_span).with(key).and_call_original
        expect(mock_tracer.span).to receive(:set_tag).with('db.type', 'redis').ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.statement', 'get').ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.instance', instance).ordered
        expect(mock_tracer.span).to receive(:set_tag).with('db.host', "redis://#{host}:#{port}").ordered
        expect(mock_tracer.span).to receive(:set_tag).with('span.kind', 'client').ordered

        expect(mock_tracer.span).to receive(:set_tag).with('error', true).ordered

        expect(caller).to receive(:foo).once

        expect { subject }.to raise_error(exception)
      end
    end
  end
end
