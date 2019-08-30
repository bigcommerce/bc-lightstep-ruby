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

describe Bigcommerce::Lightstep::Interceptors::Env do
  let(:keys) do
    {
      'git.sha': 'GIT_SHA',
      'provider.datacenter': 'DATACENTER'
    }
  end
  let(:env) do
    {
      'GIT_SHA' => '770ecc256e414c81344caa78eaa0c9272a375c71',
      'DATACENTER' => 'us-central1-a',
    }
  end
  let(:presets) { [] }
  let(:interceptor) { described_class.new(keys: keys, env: env, presets: presets) }
  let(:span) { double(:span, set_tag: true) }
  let(:root_span) { true }

  before do
    span.instance_variable_set(:@root_span, root_span)
  end

  describe '.call' do
    subject { interceptor.call(span: span) { true } }

    context 'when all ENV are present' do
      context 'with some keys' do
        it 'should set tags' do
          expect(span).to receive(:set_tag).with('git.sha', '770ecc256e414c81344caa78eaa0c9272a375c71').once.ordered
          expect(span).to receive(:set_tag).with('provider.datacenter', 'us-central1-a').once.ordered
          subject
        end

        it 'should only collect the tags once even with multiple calls' do
          expect(env).to receive(:fetch).with('GIT_SHA', nil).once.ordered
          expect(env).to receive(:fetch).with('DATACENTER', nil).once.ordered
          interceptor.call(span: span) { true }
          interceptor.call(span: span) { true }
          interceptor.call(span: span) { true }
        end
      end

      context 'with no keys' do
        let(:keys) { [] }

        it 'should not set any tags' do
          expect(span).to_not receive(:set_tag)
          subject
        end
      end

      context 'with the hostname preset' do
        let(:presets) { [:hostname] }
        let(:keys) { {} }
        let(:env) do
          {
              'HOSTNAME' => 'asdf1234',
          }
        end

        it 'should set the appropriate nomad tags' do
          expect(span).to receive(:set_tag).with('hostname', 'asdf1234').once.ordered
          subject
        end
      end

      context 'with the nomad preset' do
        let(:presets) { [:nomad] }
        let(:keys) { {} }
        let(:env) do
          {
              'NOMAD_CPU_LIMIT' => '128',
              'NOMAD_MEMORY_LIMIT' => '512',
              'NOMAD_META_SHA' => '770ecc256e414c81344caa78eaa0c9272a375c71',
              'NOMAD_NODE_ID' => 'asdf1234',
              'NOMAD_NODE_NAME' => 'nomad-client-abc789',
              'NOMAD_TASK_NAME' => 'foo-bar',
              'NOMAD_REGION' => 'us',
              'NOMAD_DC' => 'us-central1-a'
          }
        end

        it 'should set the appropriate nomad tags' do
          expect(span).to receive(:set_tag).with('container.cpu', '128').once.ordered
          expect(span).to receive(:set_tag).with('container.mem', '512').ordered
          expect(span).to receive(:set_tag).with('git.sha', '770ecc256e414c81344caa78eaa0c9272a375c71').ordered
          expect(span).to receive(:set_tag).with('nomad.node.id', 'asdf1234').ordered
          expect(span).to receive(:set_tag).with('nomad.node.name', 'nomad-client-abc789').ordered
          expect(span).to receive(:set_tag).with('nomad.task_name', 'foo-bar').ordered
          expect(span).to receive(:set_tag).with('provider.region', 'us').ordered
          expect(span).to receive(:set_tag).with('provider.datacenter', 'us-central1-a').ordered
          subject
        end
      end

      context 'when it is not the root span' do
        let(:root_span) { false }

        it 'should not set any tags' do
          expect(span).to_not receive(:set_tag)
          subject
        end
      end
    end

    context 'when ENV is not set' do
      let(:env) { { } }

      it 'should set tags to blank values' do
        expect(span).to receive(:set_tag).with('git.sha', '').once.ordered
        expect(span).to receive(:set_tag).with('provider.datacenter', '').once.ordered
        subject
      end
    end
  end
end
