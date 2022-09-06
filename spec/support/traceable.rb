# frozen_string_literal: true

class TestTracedService
  include ::Bigcommerce::Lightstep::Traceable

  trace :call, 'operation.call' do |span:, name:, should_fail:|
    span.set_tag('traced', true)
    span.set_tag('name', name)
  end
  def call(name:, should_fail:)
    raise StandardError, 'oops' if should_fail

    name
  end

  trace :call_without_block, 'operation.call_without_block'
  def call_without_block(name:, should_fail:)
    raise StandardError, 'oops' if should_fail

    name
  end

  trace :call_with_tags, 'operation.call_with_tags', tags: { foo: 'bar' } do |span:, name:|
    span.set_tag('name', name)
  end
  def call_with_tags(name:)
    name
  end
end
