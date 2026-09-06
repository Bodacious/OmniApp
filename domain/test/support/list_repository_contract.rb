# frozen_string_literal: true

require 'models/list'

##
# Behavior every List persistence backend (in-memory, Sequel/SQLite,
# PostgreSQL, ...) must provide.
#
# Include this module into a Minitest::Test subclass that implements a
# +repository+ method returning the backend under test, backed by a data
# store that starts empty for each test.
#
# Contract:
#
# [save(list)]
#   Persists +list+. When +list+ is not yet persisted, assigns it an
#   +id+. When +list+ is already persisted, updates the stored record in
#   place rather than creating a new one. Returns the (possibly mutated)
#   +list+.
# [find(id)]
#   Returns the List with the given +id+, or +nil+ if none exists.
# [find_by_slug(slug)]
#   Returns the List with the given +slug+, or +nil+ if none exists.
# [all]
#   Returns every persisted List as an Array. Returns an empty Array
#   when nothing is persisted.
# [delete_by_slug(slug)]
#   Deletes the List with the given +slug+. Returns +true+ if a List was
#   deleted, +false+ if none matched.
module ListRepositoryContract
  def test_save_assigns_an_id_to_a_new_list
    list = repository.save(List.new(name: 'Groceries'))

    refute_nil list.id
  end

  def test_save_persists_the_lists_attributes
    saved = repository.save(List.new(name: 'Groceries'))

    found = repository.find(saved.id)

    assert_equal 'Groceries', found.name
    assert_equal 'groceries', found.slug
  end

  def test_save_updates_an_already_persisted_list_instead_of_duplicating_it
    saved = repository.save(List.new(name: 'Groceries'))

    saved.name = 'Weekly groceries'
    repository.save(saved)

    assert_equal 'Weekly groceries', repository.find(saved.id).name
    assert_equal 1, repository.all.size
  end

  def test_find_returns_the_matching_list
    saved = repository.save(List.new(name: 'Groceries'))

    assert_equal saved.id, repository.find(saved.id).id
  end

  def test_find_returns_nil_when_no_list_has_that_id
    assert_nil repository.find(-1)
  end

  def test_find_by_slug_returns_the_matching_list
    saved = repository.save(List.new(name: 'Groceries'))

    assert_equal saved.id, repository.find_by_slug('groceries').id
  end

  def test_find_by_slug_returns_nil_when_no_list_has_that_slug
    assert_nil repository.find_by_slug('does-not-exist')
  end

  def test_all_returns_every_persisted_list
    repository.save(List.new(name: 'Groceries'))
    repository.save(List.new(name: 'Chores'))

    assert_equal %w[chores groceries], repository.all.map(&:slug).sort
  end

  def test_all_returns_an_empty_array_when_nothing_is_persisted
    assert_empty repository.all
  end

  def test_delete_by_slug_removes_the_list
    saved = repository.save(List.new(name: 'Groceries'))

    assert repository.delete_by_slug(saved.slug)
    assert_nil repository.find(saved.id)
  end

  def test_delete_by_slug_returns_false_when_nothing_matches
    refute repository.delete_by_slug('does-not-exist')
  end
end
