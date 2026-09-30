# frozen_string_literal: true

require 'test_helper'
require 'todo_list'
require 'support/in_memory_todo_repository'
require 'support/sequential_id_generator'

class TodoListTest < Minitest::Test
  def setup
    @repository = InMemoryTodoRepository.new
    @todo_list = TodoList.new(repository: @repository, id_generator: SequentialIdGenerator.new)
  end

  def test_there_are_no_todos_to_begin_with
    assert_empty @todo_list.todos
  end

  def test_add_stores_a_todo_with_a_generated_id
    todo = @todo_list.add('Buy milk')

    assert_equal 'todo-1', todo.id
    assert_equal [todo], @todo_list.todos
  end

  def test_add_rejects_a_blank_title_without_storing_anything
    assert_raises(Todo::Invalid) { @todo_list.add('  ') }
    assert_empty @todo_list.todos
  end

  def test_complete_marks_the_todo_as_completed
    todo = @todo_list.add('Buy milk')

    @todo_list.complete(todo.id)

    assert_predicate @todo_list.todos.first, :completed?
  end

  def test_complete_raises_not_found_for_an_unknown_todo
    assert_raises(TodoList::NotFound) { @todo_list.complete('missing') }
  end

  def test_delete_removes_the_todo
    keep = @todo_list.add('Walk dog')
    gone = @todo_list.add('Buy milk')

    @todo_list.delete(gone.id)

    assert_equal [keep], @todo_list.todos
  end

  def test_delete_raises_not_found_for_an_unknown_todo
    assert_raises(TodoList::NotFound) { @todo_list.delete('missing') }
  end
end
