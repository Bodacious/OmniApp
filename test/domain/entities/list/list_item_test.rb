# frozen_string_literal: true

require 'test_helper'
require 'domain/entities/list/item'

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
end
