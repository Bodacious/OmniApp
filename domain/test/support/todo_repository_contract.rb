# frozen_string_literal: true

require 'model/todo'

##
# The behaviour every Ports::TodoRepository adapter must provide (see
# domain/ports/todo_repository.rb). Include it into a Minitest::Test
# that defines +repository+, returning the adapter under test backed by
# an empty store.
module TodoRepositoryContract
  def test_it_implements_the_port
    assert_kind_of Ports::TodoRepository, repository
  end

  def test_in_list_is_empty_when_nothing_is_stored
    assert_equal [], repository.in_list('list-a')
  end

  def test_save_returns_the_todo
    todo = todo('1', 'Buy milk')

    assert_same todo, repository.save(todo)
  end

  def test_find_returns_a_saved_todo
    repository.save(todo('1', 'Buy milk'))

    assert_equal todo('1', 'Buy milk'), repository.find('1')
  end

  def test_find_returns_nil_for_an_unknown_id
    assert_nil repository.find('missing')
  end

  def test_in_list_returns_that_lists_todos_in_the_order_they_were_first_saved
    %w[c a b].each { |id| repository.save(todo(id, "Todo #{id}")) }
    repository.save(todo('x', 'Elsewhere', list_id: 'list-b'))

    assert_equal %w[c a b], repository.in_list('list-a').map(&:id)
    assert_equal %w[x], repository.in_list('list-b').map(&:id)
  end

  def test_save_replaces_a_todo_with_the_same_id_in_place
    repository.save(todo('1', 'Buy milk'))
    repository.save(todo('2', 'Walk dog'))

    repository.save(todo('1', 'Buy milk').complete)

    assert_equal %w[1 2], repository.in_list('list-a').map(&:id)
    assert_predicate repository.find('1'), :completed?
  end

  def test_completed_state_round_trips
    repository.save(todo('1', 'Buy milk'))
    repository.save(todo('2', 'Walk dog').complete)

    refute_predicate repository.find('1'), :completed?
    assert_predicate repository.find('2'), :completed?
  end

  def test_tags_round_trip
    repository.save(todo('1', 'Buy milk', tags: 'urgent home'))

    assert_equal %w[home urgent], repository.find('1').tags.map(&:name)
  end

  def test_in_list_returns_each_todos_own_tags
    repository.save(todo('1', 'Buy milk', tags: 'home'))
    repository.save(todo('2', 'File taxes', tags: 'work urgent'))
    repository.save(todo('3', 'Nap'))

    tags = repository.in_list('list-a').to_h { |stored| [stored.id, stored.tags.map(&:name)] }

    assert_equal({ '1' => ['home'], '2' => %w[urgent work], '3' => [] }, tags)
  end

  def test_save_replaces_the_tags_too
    repository.save(todo('1', 'Buy milk', tags: 'home urgent'))

    repository.save(todo('1', 'Buy milk', tags: 'errands'))

    assert_equal ['errands'], repository.find('1').tags.map(&:name)
  end

  def test_delete_removes_the_tags_with_the_todo
    repository.save(todo('1', 'Buy milk', tags: 'home'))
    repository.delete('1')

    repository.save(todo('1', 'Buy milk'))

    assert_empty repository.find('1').tags
  end

  def test_delete_removes_the_todo_and_returns_true
    repository.save(todo('1', 'Buy milk'))

    assert repository.delete('1')
    assert_nil repository.find('1')
  end

  def test_delete_returns_false_for_an_unknown_id
    refute repository.delete('missing')
  end

  private

  def todo(id, title, tags: [], list_id: 'list-a')
    Todo.new(id: id, list_id: list_id, title: title, tags: tags)
  end
end
