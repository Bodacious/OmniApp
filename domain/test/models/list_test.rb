# frozen_string_literal: true

require 'test_helper'
require 'models/list'

class ListTest < Minitest::Test
  def test_it_sets_the_name_on_init
    list = List.new(name: 'list-name')

    assert_equal 'list-name', list.name
  end

  def test_it_sets_the_id_on_init
    list = List.new(id: 1)

    assert_equal 1, list.id
  end

  def test_persisted_is_false_when_id_nil
    list = List.new(id: nil)

    refute_predicate list, :persisted?
  end

  def test_list_items_defaults_to_an_empty_array
    list = List.new

    assert_empty list.items
  end

  def test_list_has_many_items
    list = List.new

    item = stub('Item')
    list.items << item

    assert_includes list.items, item
  end

  def test_list_slug_is_the_name_dasherized
    list = List.new(name: 'My 100% Awesome list?')

    assert_equal('my-100-awesome-list', list.slug)
  end
end
