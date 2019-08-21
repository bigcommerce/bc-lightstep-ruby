# frozen_string_literal: true

# Copyright (c) 2019-present, BigCommerce Pty. Ltd. All rights reserved
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

describe Bigcommerce::Lightstep::Interceptors::Context do
  let(:registry) { ::Bigcommerce::Lightstep::Interceptors::Registry.new }
  let(:context) { described_class.new(interceptors: registry.all) }
  let(:interceptor1) { TestInterceptor.new(int: 1) }
  let(:interceptor2) { TestInterceptor2.new(int: 2) }
  let(:interceptor3) { TestInterceptor3.new(int: 3) }
  let(:span) { double(:span, set_tag: true) }

  describe '.intercept' do
    subject { context.intercept(span) { Math.log2(4) } }

    context 'if there are interceptors' do
      before do
        registry.use(interceptor1)
        registry.use(interceptor2)
        registry.use(interceptor3)
      end

      it 'should call each interceptor and call the original block' do
        expect(interceptor1).to receive(:call).and_call_original
        expect(interceptor2).to receive(:call).and_call_original
        expect(interceptor3).to receive(:call).and_call_original
        expect(Math).to receive(:log2).with(4).once
        expect { subject }.to_not raise_error
      end
    end

    context 'if there are no interceptors' do
      it 'should just yield the main block' do
        expect(Math).to receive(:log2).with(4).once
        expect { subject }.to_not raise_error
      end
    end
  end
end
