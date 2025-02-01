# frozen_string_literal: true

require 'test_helper'
require 'models/list_item'

class ListItemTest < Minitest::Test
  def test_it_sets_the_id_on_init
    list_item = ListItem.new(id: 1)
    assert_equal 1,list_item.id
  end

  def test_it_sets_the_list_id_on_init
    list_item = ListItem.new(list_id: 1)
    assert_equal 1,list_item.list_id
  end

  def test_it_sets_the_summary_on_init
    list_item = ListItem.new(summary: "list-item-summary")
    assert_equal 'list-item-summary', list_item.summary
  end
end
