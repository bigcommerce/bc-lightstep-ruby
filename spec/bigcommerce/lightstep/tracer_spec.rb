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

describe Bigcommerce::Lightstep::Tracer do
  let(:tracer) { described_class.instance }

  describe '#start_span' do
    subject {  }

    let(:operation_name) { 'test' }

    it 'yields a span' do
      tracer.start_span(operation_name) do |span|
        expect(span).to be_a(LightStep::Span)
      end
    end

    it 'sets the current span as the active span' do
      tracer.start_span('outer') do |outer_span|
        expect(outer_span).to be_a(LightStep::Span)
        expect(tracer.active_span).to eq outer_span
        expect(Thread.current[:lightstep_active_span]).to eq outer_span

        tracer.start_span('inner') do |inner_span|
          expect(inner_span).to be_a(LightStep::Span)
          expect(tracer.active_span).to eq inner_span
          expect(Thread.current[:lightstep_active_span]).to eq inner_span
        end
      end
    end

    it 'sets the outer span as the root span' do
      tracer.start_span('outer') do |outer_span|
        expect(outer_span.instance_variable_get(:@root_span)).to be_truthy
        tracer.start_span('inner') do |inner_span|
          expect(inner_span.instance_variable_get(:@root_span)).to be_falsey
        end
      end
    end

    context 'when the LightStep reporter is not initialized' do
      it 'returns a span regardless' do
        expect(LightStep.instance.instance_variable_get(:@reporter)).to be_nil

        expect do
          tracer.start_span(operation_name) do |span|
            expect(span).to be_a(LightStep::Span)
          end
        end.not_to raise_error
      end
    end
  end
end
