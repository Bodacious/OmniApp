# frozen_string_literal: true

require 'model/list_repository'
require 'model/user'

##
# The behaviour every ListRepository implementation must provide (see
# domain/model/list_repository.rb). Include it into a Minitest::Test
# that defines +list_repository+, returning the implementation under
# test backed by an empty store.
#
# It is plain Minitest, so it also runs in the browser, on CRuby's own
# stdlib (apps/ruby_wasm).
module ListRepositoryContract
  ADA = User.new(id: 'ada', email: 'ada@example.com', password_digest: 'digest')
  BOB = User.new(id: 'bob', email: 'bob@example.com', password_digest: 'digest')

  def test_list_repository_is_a_list_repository
    assert_kind_of ListRepository, list_repository
  end

  def test_next_identity_is_a_new_string_every_time
    ids = Array.new(3) { list_repository.next_identity }

    assert_equal 3, ids.uniq.size
    assert_kind_of String, ids.first
  end

  def test_find_is_nil_for_an_unknown_id
    assert_nil list_repository.find('missing')
  end

  def test_save_returns_the_list
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')

    assert_same list, list_repository.save(list)
  end

  def test_find_returns_a_saved_list
    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))

    assert_equal List.new(id: 'a', owner_id: 'ada', name: 'Groceries'), list_repository.find('a')
  end

  def test_owned_by_returns_only_that_users_lists_in_the_order_they_were_first_saved
    list_repository.save(List.new(id: 'b', owner_id: 'ada', name: 'Work'))
    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))
    list_repository.save(List.new(id: 'c', owner_id: 'bob', name: 'Bob stuff'))

    assert_equal [%w[b a], %w[c]], [list_repository.owned_by(ADA).map(&:id), list_repository.owned_by(BOB).map(&:id)]
  end

  def test_owned_by_is_empty_for_a_user_with_no_lists
    assert_empty list_repository.owned_by(ADA)
  end

  def test_save_replaces_a_list_with_the_same_id_in_place
    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))
    list_repository.save(List.new(id: 'b', owner_id: 'ada', name: 'Work'))

    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Weekly shop'))

    assert_equal ['Weekly shop', 'Work'], list_repository.owned_by(ADA).map(&:name)
  end

  def test_todos_round_trip_with_the_list_in_order
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    %w[c a b].each { |id| list.add(id: id, title: "Todo #{id}") }

    list_repository.save(list)

    assert_equal %w[c a b], list_repository.find('a').todos.map(&:id)
  end

  def test_completed_state_round_trips
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    list.add(id: '1', title: 'Buy milk')
    list.add(id: '2', title: 'Walk dog')
    list.complete('2')

    list_repository.save(list)

    assert_equal [false, true], list_repository.find('a').todos.map(&:completed?)
  end

  def test_each_todo_keeps_its_own_tags
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    list.add(id: '1', title: 'Buy milk', tags: 'home')
    list.add(id: '2', title: 'File taxes', tags: 'work urgent')
    list.add(id: '3', title: 'Nap')

    list_repository.save(list)

    tags = list_repository.find('a').todos.to_h { |todo| [todo.id, todo.tags.map(&:name)] }

    assert_equal({ '1' => ['home'], '2' => %w[urgent work], '3' => [] }, tags)
  end

  def test_lists_keep_their_todos_apart
    groceries = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    groceries.add(id: '1', title: 'Buy milk')
    work = List.new(id: 'b', owner_id: 'ada', name: 'Work')
    work.add(id: '2', title: 'File taxes')

    list_repository.save(groceries)
    list_repository.save(work)

    assert_equal [['Buy milk'], ['File taxes']], [list_repository.find('a').todos.map(&:title),
                                                  list_repository.find('b').todos.map(&:title)]
  end

  def test_saving_again_stores_exactly_the_lists_todos_now
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    list.add(id: '1', title: 'Buy milk', tags: 'home urgent')
    list.add(id: '2', title: 'Walk dog')
    list.add(id: '3', title: 'Nap')
    list_repository.save(list)

    list.remove('2')
    list.tag('1', 'errands')
    list.untag('1', 'urgent')
    list.complete('3')
    list.add(id: '4', title: 'Call mum')
    list_repository.save(list)

    assert_equal list, list_repository.find('a')
  end

  def test_a_removed_todo_takes_its_tags_with_it
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    list.add(id: '1', title: 'Buy milk', tags: 'home')
    list_repository.save(list)
    list.remove('1')
    list_repository.save(list)

    list.add(id: '1', title: 'Buy milk')
    list_repository.save(list)

    assert_empty list_repository.find('a').todo('1').tags
  end

  def test_a_found_list_is_a_copy_until_it_is_saved
    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))

    list_repository.find('a').add(id: '1', title: 'Buy milk')

    assert_empty list_repository.find('a').todos
  end

  def test_remove_takes_the_list_and_its_todos
    list = List.new(id: 'a', owner_id: 'ada', name: 'Groceries')
    list.add(id: '1', title: 'Buy milk', tags: 'home')
    list_repository.save(list)

    list_repository.remove(list)

    assert_nil list_repository.find('a')
  end

  def test_remove_leaves_other_lists_alone
    list_repository.save(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))
    work = List.new(id: 'b', owner_id: 'ada', name: 'Work')
    work.add(id: '1', title: 'File taxes')
    list_repository.save(work)

    list_repository.remove(List.new(id: 'a', owner_id: 'ada', name: 'Groceries'))

    assert_equal [work], list_repository.owned_by(ADA)
  end
end
