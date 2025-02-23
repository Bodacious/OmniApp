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

  def test_list_refresh_re_populates_with_repeatable_items_marked_as_pending
    list = List.new name: "list-name"
    list_item = stub("ListItem", summary: "list-item-summary", repeatable?: true,
                                 pending?: true)
    list.add_item(list_item)

    list.refresh

    assert_includes list.pending_items, list_item
  end

  def test_list_refresh_re_populates_with_repeatable_items_marked_as_done
    list = List.new name: "list-name"
    list_item = stub("ListItem", summary: "list-item-summary", repeatable?: true,
                     pending?: false)
    new_list_item = stub("NewListItem", summary: "list-item-summary", repeatable?: true,
                         pending?: true)
    list.add_item(list_item)
    list_item.expects(:dup).returns(new_list_item)
    list.refresh

    assert_predicate list.pending_items.first, :pending?
  end

  def test_list_refresh_does_not_repopulate_with_non_repeatable_items_that_are_not_pending?
    list = List.new name: "list-name"
    list_item = stub("ListItem", summary: "list-item-summary", repeatable?: false,
                                 pending?: false)
    list.add_item(list_item)

    assert_empty list.pending_items

    list.refresh

    assert_empty list.pending_items
  end

  def test_list_refresh_carries_over_undone_items_that_are_not_repeatable
    list = List.new name: "list-name"
    list_item = stub("ListItem", summary: "list-item-summary", repeatable?: false,
                                 pending?: true)
    list.add_item(list_item)

    assert_includes list.pending_items, list_item

    list.refresh

    assert_includes list.pending_items, list_item
  end
end
