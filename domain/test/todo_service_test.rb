# frozen_string_literal: true

require 'test_helper'
require 'todo_service'
require 'support/in_memory_list_repository'
require 'support/in_memory_todo_repository'
require 'support/sequential_id_generator'

class TodoServiceTest < Minitest::Test
  def setup
    @lists = InMemoryListRepository.new
    @todos = InMemoryTodoRepository.new
    @ids = SequentialIdGenerator.new
    @service = TodoService.new(lists: @lists, todos: @todos, id_generator: @ids)
    @ada = User.new(id: 'ada', email: 'ada@example.com', password_digest: 'd')
    @bob = User.new(id: 'bob', email: 'bob@example.com', password_digest: 'd')
  end

  # --- lists

  def test_a_new_user_has_no_lists
    assert_empty @service.lists(@ada)
  end

  def test_create_list_gives_the_user_a_list
    list = @service.create_list(@ada, ' Groceries ')

    assert_equal 'Groceries', list.name
    assert_equal [list], @service.lists(@ada)
  end

  def test_users_see_only_their_own_lists
    @service.create_list(@ada, 'Groceries')

    assert_empty @service.lists(@bob)
  end

  def test_a_blank_list_name_is_rejected_without_spending_an_id
    assert_raises(List::Invalid) { @service.create_list(@ada, ' ') }
    assert_equal 'todo-1', @ids.next_id
  end

  def test_opening_someone_elses_list_is_not_found
    list = @service.create_list(@ada, 'Groceries')

    error = assert_raises(TodoService::NotFound) { @service.list(@bob, list.id) }
    assert_equal 'No such list', error.message
    assert_raises(TodoService::NotFound) { @service.list(@ada, 'missing') }
  end

  def test_delete_list_removes_it_and_its_todos
    list = @service.create_list(@ada, 'Groceries')
    milk = @service.list(@ada, list.id).add('Buy milk')

    @service.delete_list(@ada, list.id)

    assert_empty @service.lists(@ada)
    assert_nil @todos.find(milk.id)
  end

  def test_users_cannot_delete_someone_elses_list
    list = @service.create_list(@ada, 'Groceries')

    assert_raises(TodoService::NotFound) { @service.delete_list(@bob, list.id) }
    assert_equal [list], @service.lists(@ada)
  end

  # --- todos on a list

  def test_add_stores_a_todo_on_the_list
    groceries = open('Groceries')

    todo = groceries.add('Buy milk', 'Errands, #home')

    assert_equal groceries.id, todo.list_id
    assert_equal [todo], groceries.todos
    assert_equal %w[errands home], todo.tags.map(&:name)
  end

  def test_lists_keep_their_todos_apart
    groceries = open('Groceries')
    work = open('Work')
    groceries.add('Buy milk')
    work.add('File taxes')

    assert_equal ['Buy milk'], groceries.todos.map(&:title)
    assert_equal ['File taxes'], work.todos.map(&:title)
  end

  def test_add_rejects_bad_input_without_storing_anything_or_spending_an_id
    groceries = open('Groceries')
    next_id = @ids.next_id.succ

    assert_raises(Todo::Invalid) { groceries.add('  ') }
    assert_raises(Tag::Invalid) { groceries.add('Buy milk', 'not ok!') }
    assert_empty groceries.todos
    assert_equal next_id, @ids.next_id
  end

  def test_complete_tag_and_untag
    groceries = open('Groceries')
    todo = groceries.add('Buy milk', 'home')

    groceries.complete(todo.id)
    groceries.tag(todo.id, 'urgent')
    groceries.untag(todo.id, 'home')

    stored = @todos.find(todo.id)
    assert_predicate stored, :completed?
    assert_equal ['urgent'], stored.tags.map(&:name)
  end

  def test_tag_enforces_the_most_tags_a_todo_can_have
    groceries = open('Groceries')
    todo = groceries.add('Busy', 'a b c d e')

    assert_raises(Todo::Invalid) { groceries.tag(todo.id, 'f') }
    assert_equal 5, @todos.find(todo.id).tags.size
  end

  def test_todos_can_be_filtered_by_tag_and_tags_are_counted_per_list
    groceries = open('Groceries')
    milk = groceries.add('Buy milk', 'home errands')
    groceries.add('File taxes', 'work')
    mum = groceries.add('Call mum', 'Home')
    open('Work').add('Elsewhere', 'home')

    assert_equal [milk.id, mum.id], groceries.todos(tagged: '#home').map(&:id)
    assert_equal 3, groceries.todos(tagged: '').size
    counts = groceries.tags.map { |count| [count.tag.name, count.todo_count] }
    assert_equal [['errands', 1], ['home', 2], ['work', 1]], counts
  end

  def test_a_todo_from_another_list_is_not_found
    groceries = open('Groceries')
    work = open('Work')
    taxes = work.add('File taxes')

    %i[complete delete].each do |use_case|
      assert_raises(TodoService::NotFound) { groceries.public_send(use_case, taxes.id) }
    end
    assert_raises(TodoService::NotFound) { groceries.tag(taxes.id, 'x') }
    refute_predicate @todos.find(taxes.id), :completed?
  end

  def test_a_todo_on_someone_elses_list_cannot_be_reached
    adas = open('Groceries')
    milk = adas.add('Buy milk')
    bobs = @service.list(@bob, @service.create_list(@bob, 'Mine').id)

    assert_raises(TodoService::NotFound) { bobs.delete(milk.id) }
    assert_equal [milk], adas.todos
  end

  def test_delete_removes_the_todo
    groceries = open('Groceries')
    keep = groceries.add('Walk dog')
    gone = groceries.add('Buy milk')

    groceries.delete(gone.id)

    assert_equal [keep], groceries.todos
  end

  private

  def open(name, user = @ada)
    @service.list(user, @service.create_list(user, name).id)
  end
end
