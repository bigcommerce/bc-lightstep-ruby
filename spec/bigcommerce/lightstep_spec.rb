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

describe Bigcommerce::Lightstep do
  let(:access_token) { 'abcd' }
  let(:transport) { ::Bigcommerce::Lightstep::Transport.new(access_token: access_token) }
  let(:transport_factory) { ::Bigcommerce::Lightstep::TransportFactory.new }
  let(:component_name) { 'foo' }

  describe '#start' do
    let(:max_buffered_spans) { Bigcommerce::Lightstep.max_buffered_spans }
    let(:max_log_records) { Bigcommerce::Lightstep.max_log_records }
    let(:max_reporting_interval_seconds) { Bigcommerce::Lightstep.max_reporting_interval_seconds }

    subject { described_class.start(transport_factory: transport_factory, component_name: component_name) }

    before do
      allow(transport_factory).to receive(:build).and_return(transport)
      allow_any_instance_of(LightStep::Reporter).to receive(:reset_on_fork)
    end

    it 'should properly configure lightstep' do
      expect(::LightStep).to receive(:configure).with(
        component_name: component_name,
        transport: transport
      ).and_call_original

      expect(LightStep.instance).to receive(:max_span_records=).with(max_buffered_spans)
      expect(LightStep.instance.max_span_records).to eq max_buffered_spans
      expect(LightStep.instance).to receive(:max_log_records=).with(max_log_records)
      expect(LightStep.instance.max_log_records).to eq max_log_records
      expect(LightStep.instance).to receive(:report_period_seconds=).with(max_reporting_interval_seconds)
      subject
    end
  end
end
