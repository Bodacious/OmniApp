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
    list_item = stub("ListItem", summary: "list-item-summary")

    list.add_item(list_item)

    assert_includes list.items, list_item
  end

  def test_list_can_remove_an_item
    list = List.new
    list_item = stub("ListItem", summary: "list-item-summary")

    list.add_item(list_item)

    assert_includes list.items, list_item

    list.remove_item(list_item)

    assert_empty list.items
  end

  def test_pending_items_returns_the_list_items_that_are_pending
    list = List.new name: "list-name"
    pending_list_item = stub("PendingListItem", summary: "pending-list-item",
                                                pending?: true)
    done_list_item = stub("DoneListItem", summary: "pending-list-item", pending?: false)
    list.add_item(pending_list_item)
    list.add_item(done_list_item)

    assert_includes list.pending_items, pending_list_item
    refute_includes list.pending_items, done_list_item
  end

  def test_list_refresh_refreshes_the_list_items_set
    list = List.new
    list_items = stub('ListItems')
    list.stubs(items: list_items)

    list_items.expects(:refresh).returns(stub('NewListItems'))

    list.refresh
  end
end
