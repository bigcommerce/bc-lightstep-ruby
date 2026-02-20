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
# frozen_string_literal: true

require 'spec_helper'

describe Bigcommerce::Lightstep::Middleware::Faraday do
  let(:tracer) { instance_double(Bigcommerce::Lightstep::Tracer) }
  let(:span_context) { instance_double(LightStep::SpanContext, trace_id: 123, id: 456) }
  let(:span) { instance_double(LightStep::Span, context: span_context, set_tag: true) }

  before do
    allow(Bigcommerce::Lightstep::Tracer).to receive(:instance).and_return(tracer)
    allow(tracer).to receive(:start_span).and_yield(span)
  end

  describe '#call' do
    let(:service_name) { 'payments-v1.api' }
    let(:captured_headers) { {} }
    let(:status) { 200 }
    let(:connection) do
      Faraday.new(url: 'https://example.com') do |f|
        f.use(described_class, service_name)
        f.adapter(:test) do |stub|
          stub.get('/resource') do |env|
            captured_headers.merge!(env.request_headers)
            [status, { 'Content-Type' => 'application/json' }, '{}']
          end
        end
      end
    end

    it 'injects trace headers and tags successful responses' do
      expect(tracer).to receive(:start_span).with('payments_v1_api', context: kind_of(Hash)).and_yield(span)
      expect(span).to receive(:set_tag).with('http.url', 'https://example.com/resource').ordered
      expect(span).to receive(:set_tag).with('http.method', 'get').ordered
      expect(span).to receive(:set_tag).with('http.external-service', true).ordered
      expect(span).to receive(:set_tag).with('span.kind', 'client').ordered
      expect(span).to receive(:set_tag).with('http.status_code', '200').ordered

      response = connection.get('/resource?foo=bar')

      expect(response.status).to eq(200)
      expect(captured_headers).to include(
        'ot-tracer-traceid' => '123',
        'ot-tracer-spanid' => '456',
        'ot-tracer-sampled' => 'true'
      )
    end

    context 'when the response status is an HTTP error' do
      let(:status) { 500 }

      it 'tags the span as an error' do
        expect(span).to receive(:set_tag).with('http.status_code', '500').ordered
        expect(span).to receive(:set_tag).with('error', true).ordered

        response = connection.get('/resource')
        expect(response.status).to eq(500)
      end
    end

    context 'when the request fails with Faraday::ConnectionFailed' do
      let(:connection) do
        Faraday.new(url: 'https://example.com') do |f|
          f.use(described_class, service_name)
          f.adapter(:test) do |stub|
            stub.get('/resource') { |_env| raise Faraday::ConnectionFailed, 'connection failed' }
          end
        end
      end

      it 'tags the span as an error and uses service unavailable status' do
        expect(span).to receive(:set_tag).with('error', true)
        expect(span).to receive(:set_tag).with('http.status_code', 503)

        expect { connection.get('/resource') }.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context 'when the request fails with Net::ReadTimeout' do
      let(:connection) do
        Faraday.new(url: 'https://example.com') do |f|
          f.use(described_class, service_name)
          f.adapter(:test) do |stub|
            stub.get('/resource') { |_env| raise Net::ReadTimeout }
          end
        end
      end

      it 'tags the span as an error and uses request timeout status' do
        expect(span).to receive(:set_tag).with('error', true)
        expect(span).to receive(:set_tag).with('http.status_code', 408)

        expect { connection.get('/resource') }.to raise_error(Net::ReadTimeout)
      end
    end

    context 'when the request fails with Faraday::ClientError' do
      let(:connection) do
        Faraday.new(url: 'https://example.com') do |f|
          f.use(described_class, service_name)
          f.adapter(:test) do |stub|
            stub.get('/resource') { |_env| raise Faraday::ClientError.new('client error', nil) }
          end
        end
      end

      it 'tags the span as an error and uses internal server error status' do
        expect(span).to receive(:set_tag).with('error', true)
        expect(span).to receive(:set_tag).with('http.status_code', 500)

        expect { connection.get('/resource') }.to raise_error(Faraday::ClientError)
      end
    end
  end
end
