# frozen_string_literal: true

require 'test_helper'
require 'todo'

class TodoTest < Minitest::Test
  def test_it_has_an_id_and_a_title
    todo = Todo.new(id: 'abc', title: 'Buy milk')

    assert_equal 'abc', todo.id
    assert_equal 'Buy milk', todo.title
  end

  def test_it_is_not_completed_by_default
    refute_predicate Todo.new(id: 'abc', title: 'Buy milk'), :completed?
  end

  def test_the_title_is_stripped
    assert_equal 'Buy milk', Todo.new(id: 'abc', title: "  Buy milk \n").title
  end

  def test_a_blank_title_is_invalid
    ['', '   ', "\n\t", nil].each do |title|
      error = assert_raises(Todo::Invalid) { Todo.new(id: 'abc', title: title) }

      assert_equal "Title can't be blank", error.message
    end
  end

  def test_an_id_is_required
    assert_raises(ArgumentError) { Todo.new(id: nil, title: 'Buy milk') }
  end

  def test_complete_returns_a_completed_copy_and_leaves_the_original_alone
    todo = Todo.new(id: 'abc', title: 'Buy milk')

    completed = todo.complete

    assert_predicate completed, :completed?
    assert_equal 'abc', completed.id
    assert_equal 'Buy milk', completed.title
    refute_predicate todo, :completed?
  end

  def test_todos_with_the_same_state_are_equal
    assert_equal Todo.new(id: 'a', title: 'x'), Todo.new(id: 'a', title: 'x')
    refute_equal Todo.new(id: 'a', title: 'x'), Todo.new(id: 'a', title: 'x').complete
  end
end
