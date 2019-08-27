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

class TestConfiguration
  include Bigcommerce::Lightstep::Configuration
end
describe Bigcommerce::Lightstep::Configuration do
  let(:obj) { TestConfiguration.new }
  let(:env) { {} }

  before do
    allow(obj).to receive(:env).and_return(env)
  end

  describe '.reset' do
    subject { obj.port }

    it 'should reset config vars to default' do
      obj.configure do |c|
        c.port = 1234
      end
      obj.reset
      expect(subject).to_not eq 1234
    end
  end

  describe '.environment' do
    subject { obj.environment }

    context 'ENV RAILS_ENV' do
      let(:env) do
        {
          'RAILS_ENV' => 'production'
        }
      end

      it 'should return the proper environment' do
        expect(subject).to eq 'production'
      end
    end

    context 'ENV RACK_ENV' do
      let(:env) do
        {
          'RACK_ENV' => 'production'
        }
      end

      it 'should return the proper environment' do
        expect(subject).to eq 'production'
      end
    end
  end

  describe '.release' do
    let(:app_name) { 'users' }
    let(:sha) { 'asdf' }
    let(:release) { "#{app_name}@#{sha}" }

    subject { obj.release }

    context 'when the LIGHTSTEP_RELEASE env var is set' do
      let(:env) do
        {
          'LIGHTSTEP_RELEASE' => "#{app_name}@#{sha}"
        }
      end

      it 'should return the proper release name' do
        expect(subject).to eq release
      end
    end

    context 'when the LIGHTSTEP_RELEASE_SHA and LIGHTSTEP_APP_NAME vars are set' do
      let(:env) do
        {
          'LIGHTSTEP_RELEASE_SHA' => sha,
          'LIGHTSTEP_APP_NAME' => app_name
        }
      end

      it 'should return the proper release name' do
        expect(subject).to eq release
      end
    end

    context 'when the NOMAD_JOB_NAME and NOMAD_META_RELEASE_SHA vars are set' do
      let(:env) do
        {
          'NOMAD_META_RELEASE_SHA' => sha,
          'NOMAD_JOB_NAME' => app_name
        }
      end

      it 'should return the proper release name' do
        expect(subject).to eq release
      end
    end
  end

  describe '.options' do
    subject { obj.options }
    before do
      obj.reset
    end

    it 'should return the options hash' do
      expect(obj.options).to be_a(Hash)
      expect(obj.options[:port]).to eq 4140
    end
  end
end
