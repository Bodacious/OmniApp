# frozen_string_literal: true

require 'model/list'

##
# The behaviour every Ports::ListRepository adapter must provide (see
# domain/ports/list_repository.rb). Include it into a Minitest::Test
# that defines +list_repository+, returning the adapter under test
# backed by an empty store.
module ListRepositoryContract
  def test_list_repository_implements_the_port
    assert_kind_of Ports::ListRepository, list_repository
  end

  def test_owned_by_returns_only_that_users_lists_in_the_order_they_were_first_saved
    list_repository.save(list('b', 'ada', 'Work'))
    list_repository.save(list('a', 'ada', 'Groceries'))
    list_repository.save(list('c', 'bob', 'Bob stuff'))

    assert_equal %w[b a], list_repository.owned_by('ada').map(&:id)
    assert_equal %w[c], list_repository.owned_by('bob').map(&:id)
    assert_empty list_repository.owned_by('nobody')
  end

  def test_find_returns_a_saved_list_or_nil
    list_repository.save(list('a', 'ada', 'Groceries'))

    assert_equal list('a', 'ada', 'Groceries'), list_repository.find('a')
    assert_nil list_repository.find('missing')
  end

  def test_save_replaces_a_list_with_the_same_id_in_place
    list_repository.save(list('a', 'ada', 'Groceries'))
    list_repository.save(list('b', 'ada', 'Work'))

    list_repository.save(list('a', 'ada', 'Weekly shop'))

    assert_equal ['Weekly shop', 'Work'], list_repository.owned_by('ada').map(&:name)
  end

  def test_delete_removes_the_list_and_says_whether_it_did
    list_repository.save(list('a', 'ada', 'Groceries'))

    assert list_repository.delete('a')
    assert_nil list_repository.find('a')
    refute list_repository.delete('a')
  end

  private

  def list(id, owner_id, name)
    List.new(id: id, owner_id: owner_id, name: name)
  end
end
