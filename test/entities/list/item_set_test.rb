# frozen_string_literal: true

require 'test_helper'
require 'domain/entities/list/item_set'

class List
  class ItemSetTest < Minitest::Test
    def test_refresh_does_not_refersh_non_repeatable_items_that_are_not_pending?
      set = List::ItemSet.new
      list_item = stub("ListItem",
                       {
                         summary: "list-item-summary",
                         repeatable?: false,
                         pending?: false
                       })
      set.add(list_item)

      list_item.expects(:refresh).never

      set.refresh
    end

    def test_refresh_replaces_done_with_pending_if_repeatable?
      set = List::ItemSet.new
      list_item = stub("ListItem",
                       {
                         summary: "list-item-summary",
                         repeatable?: true,
                         pending?: false
                       })
      set.add(list_item)

      list_item.expects(:refresh).returns(stub("NewListItem",
                                               {
                                                 summary: "list-item-summary",
                                                 repeatable?: true,
                                                 pending?: true
                                               }))

      set.refresh
    end

    def test_refresh_brings_pending_items_forward_even_if_not_repeatable?
      set = List::ItemSet.new
      list_item = stub("ListItem",
                       {
                         summary: "list-item-summary",
                         repeatable?: false,
                         pending?: true
                       })
      set.add(list_item)

      list_item.expects(:refresh).returns(stub("NewListItem",
                                               {
                                                 summary: "list-item-summary",
                                                 repeatable?: false,
                                                 pending?: true
                                               }))

      set.refresh
    end

    def test_refresh_brings_pending_items_forward_if_repeatable?
      set = List::ItemSet.new
      list_item = stub("ListItem",
                       {
                         summary: "list-item-summary",
                         repeatable?: true,
                         pending?: true
                       })
      set.add(list_item)

      list_item.expects(:refresh).returns(stub("NewListItem",
                                               {
                                                 summary: "list-item-summary",
                                                 repeatable?: false,
                                                 pending?: true
                                               }))

      set.refresh
    end
  end
end
