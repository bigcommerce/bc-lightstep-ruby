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

describe Bigcommerce::Lightstep::Interceptors::Registry do
  let(:registry) { described_class.new }
  let(:interceptor_class) { TestInterceptor }
  let(:interceptor_class2) { TestInterceptor2 }
  let(:interceptor_class3) { TestInterceptor3 }
  let(:interceptor_class4) { TestInterceptor4 }
  let(:interceptor_options) { { one: 'two' } }

  describe '.use' do
    subject { registry.use(interceptor_class, interceptor_options) }
    it 'should add the interceptor to the registry' do
      expect { subject }.to_not raise_error
      expect(registry.count).to eq 1
      expect(registry.instance_variable_get('@registry').first).to eq(
        klass: interceptor_class,
        options: interceptor_options
      )
    end
  end

  describe '.clear' do
    subject { registry.clear }

    before do
      registry.use(interceptor_class)
      registry.use(interceptor_class2)
    end

    it 'should clear the registry of interceptors' do
      expect { subject }.not_to raise_error
      expect(registry.count).to be_zero
    end
  end

  describe '.count' do
    subject { registry.count }

    context 'with no interceptors' do
      it 'should return 0' do
        expect(subject).to be_zero
      end
    end

    context 'with one interceptor' do
      before do
        registry.use(interceptor_class)
      end

      it 'should return 1' do
        expect(subject).to eq 1
      end
    end

    context 'with multiple interceptors' do
      before do
        registry.use(interceptor_class)
        registry.use(interceptor_class2)
        registry.use(interceptor_class3)
      end

      it 'should return the number' do
        expect(subject).to eq 3
      end
    end
  end

  describe '.all' do
    let(:request) { build :controller_request }
    let(:errors) { build :error }
    subject { registry.all }

    before do
      registry.use(interceptor_class)
      registry.use(interceptor_class3)
      registry.use(interceptor_class2)
    end

    it 'should return all the interceptors prepared by the request and maintain insertion order' do
      prepped = subject
      expect(prepped.count).to eq 3
      expect(prepped[0]).to be_a(interceptor_class)
      expect(prepped[1]).to be_a(interceptor_class3)
      expect(prepped[2]).to be_a(interceptor_class2)
    end
  end
end
