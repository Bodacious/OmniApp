require "test_helper"
require "domain/entities/list"

class ListTest < Minitest::Test
  def test_list_has_a_name
    list = List.new(name: "list-name")

    assert_equal "list-name", list.name
  end

  def test_list_has_many_list_items
    list = List.new

    assert_empty list.items
  end

  def test_list_can_accept_an_item
    list = List.new
    list_item = List::Item.new(summary: "list-item-summary")

    list.add_item(list_item)

    assert_includes list.items, list_item
  end

  def test_list_can_remove_an_item
    list = List.new
    list_item = List::Item.new(summary: "list-item-summary")

    list.add_item(list_item)
    assert_includes list.items, list_item

    list.remove_item(list_item)

    assert_empty list.items
  end

end
