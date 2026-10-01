# frozen_string_literal: true

require 'test_helper'
require 'model/list'
require 'model/user'

class ListTest < Minitest::Test
  def test_it_has_an_id_an_owner_and_a_stripped_name
    list = List.new(id: 'l1', owner_id: 'u1', name: '  Groceries ')

    assert_equal 'l1', list.id
    assert_equal 'u1', list.owner_id
    assert_equal 'Groceries', list.name
  end

  def test_a_blank_name_is_invalid
    error = assert_raises(List::Invalid) { List.new(id: 'l1', owner_id: 'u1', name: '  ') }

    assert_equal "Name can't be blank", error.message
  end

  def test_a_long_name_is_invalid
    assert_raises(List::Invalid) { List.normalize_name('x' * 61) }
  end

  def test_it_is_owned_by_its_owner_only
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert list.owned_by?(User.new(id: 'u1', email: 'ada@example.com', password_digest: 'd'))
    refute list.owned_by?(User.new(id: 'u2', email: 'bob@example.com', password_digest: 'd'))
    refute list.owned_by?(nil)
  end
end
