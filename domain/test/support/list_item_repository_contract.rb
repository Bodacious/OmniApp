# frozen_string_literal: true

require 'models/list'
require 'models/list_item'

##
# Behavior every ListItem persistence backend (in-memory, browser
# localStorage, ...) must provide.
#
# Include this module into a Minitest::Test subclass that implements a
# +repository+ method returning the backend under test, backed by a
# data store that starts empty for each test.
#
# Contract:
#
# [save(list_item)]
#   Persists +list_item+, assigning it an +id+ if it doesn't have one
#   yet. Returns the (possibly mutated) +list_item+.
# [all_for_list(list)]
#   Returns every ListItem whose +list_id+ matches +list.id+, as an
#   Array. Returns an empty Array when none match.
# [delete(id)]
#   Deletes the ListItem with the given +id+. Returns +true+ if a
#   ListItem was deleted, +false+ if none matched.
module ListItemRepositoryContract
  def test_save_assigns_an_id_to_a_new_item
    item = repository.save(ListItem.new(summary: 'Milk', list_id: 1))

    refute_nil item.id
  end

  def test_all_for_list_returns_only_items_belonging_to_that_list
    list = list_with_id(1)
    save_item('Milk', list.id)
    save_item('Bread', list.id)
    save_item('Vacuum', list_with_id(2).id)

    summaries = repository.all_for_list(list).map(&:summary)

    assert_equal %w[Bread Milk], summaries.sort
  end

  def test_all_for_list_returns_an_empty_array_when_none_match
    assert_empty repository.all_for_list(list_with_id(1))
  end

  def test_delete_removes_the_item
    item = repository.save(ListItem.new(summary: 'Milk', list_id: 1))

    assert repository.delete(item.id)
    assert_empty repository.all_for_list(list_with_id(1))
  end

  def test_delete_returns_false_when_nothing_matches
    refute repository.delete(-1)
  end

  private

  def list_with_id(id)
    List.new(name: "list-#{id}").tap { |list| list.id = id }
  end

  def save_item(summary, list_id)
    repository.save(ListItem.new(summary: summary, list_id: list_id))
  end
end
