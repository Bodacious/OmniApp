# frozen_string_literal: true

require "test_helper"
require "domain/entities/list/item"

class List
  class ListItemTest < Minitest::Test
    def test_it_has_a_summary
      list_item = List::Item.new(summary: "list-item-summary")

      assert_equal "list-item-summary", list_item.summary
    end

    def test_it_is_not_done_by_default
      list_item = List::Item.new

      refute_predicate list_item, :done?
    end

    def test_toggle_done_toggles_done_value
      list_item = List::Item.new

      refute_predicate list_item, :done?
      list_item.toggle_done

      assert_predicate list_item, :done?
      list_item.toggle_done

      refute_predicate list_item, :done?
    end

    def test_list_items_can_be_repeatable
      list_item = List::Item.new repeatable: true

      assert_predicate list_item, :repeatable?

      list_item = List::Item.new repeatable: false

      refute_predicate list_item, :repeatable?
    end

    def test_toggle_repeatable_changes_the_repeatable_value
      list_item = List::Item.new

      refute_predicate list_item, :repeatable?

      list_item.toggle_repeatable

      assert_predicate list_item, :repeatable?
    end
  end
end
