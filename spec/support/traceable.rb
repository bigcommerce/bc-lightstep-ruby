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

  trace :call_with_single_hash_arg, 'operation.call_with_single_hash_arg' do |my_hash|
    my_hash[:span].set_tag('one', my_hash[:one])
    my_hash[:span].set_tag('two', my_hash[:two])
  end
  def call_with_single_hash_arg(my_hash)
    my_hash
  end

  trace :call_with_multiple_hash_args, 'operation.call_with_single_hash_arg' do |span, hash_1, hash_2|
    span.set_tag('one', hash_1[:one])
    span.set_tag('two', hash_2[:two])
  end
  def call_with_multiple_hash_args(hash_1, hash_2)
    [hash_1, hash_2]
  end

  trace :call_with_positional_args, 'operation.call_with_positional_args' do |span, one, two, three|
    span.set_tag('one', one)
    span.set_tag('two', two)
    span.set_tag('three', three)
  end
  def call_with_positional_args(one, two, three = 'baz')
    [one, two, three]
  end
end
