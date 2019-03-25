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

describe Bigcommerce::Lightstep::Transport do
  let(:access_token) { 'abcd1234' }
  let(:verbose) { 3 }
  let(:logger) { NullLogger.new }
  let(:params) do
    {
      access_token: access_token,
      logger: logger,
      verbose: verbose
    }
  end
  let(:transport) { described_class.new(params) }

  describe 'initialization' do
    subject { transport }

    context 'if all required parameters are present' do
      it 'should return the initialized object' do
        expect(subject).to be_a(described_class)
      end
    end
  end

  describe '.report' do
    let(:report) { {} }
    let(:response) { '' }
    subject { transport.report(report) }

    context 'if the submission is successful' do
      before do
        expect_any_instance_of(::Net::HTTP).to receive(:request).and_return(response)
      end

      it 'should send the request and return nil' do
        expect(logger).to receive(:info).with(report)
        expect(logger).to receive(:info).with(response.to_s)
        subject
      end
    end

    context 'if the submission raises an exception' do
      let(:error_message) { 'foo' }
      let(:exception) { StandardError.new(error_message) }

      before do
        expect_any_instance_of(::Net::HTTP).to receive(:request).and_raise(exception)
      end

      it 'should pass through' do
        expect(logger).to receive(:info).with(report)

        expect { subject }.to raise_error(exception, error_message)
      end
    end
  end
end
