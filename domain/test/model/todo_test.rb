# frozen_string_literal: true

require 'test_helper'
require 'model/todo'

class TodoTest < Minitest::Test
  def test_it_has_an_id_and_a_title
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk')

    assert_equal 'abc', todo.id
    assert_equal 'Buy milk', todo.title
  end

  def test_it_is_not_completed_and_untagged_by_default
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk')

    refute_predicate todo, :completed?
    assert_empty todo.tags
  end

  def test_the_title_is_stripped
    assert_equal 'Buy milk', Todo.new(id: 'abc', list_id: 'l1', title: "  Buy milk \n").title
  end

  def test_a_blank_title_is_invalid
    ['', '   ', "\n\t", nil].each do |title|
      error = assert_raises(Todo::Invalid) { Todo.new(id: 'abc', list_id: 'l1', title: title) }

      assert_equal "Title can't be blank", error.message
    end
  end

  def test_an_id_and_a_list_are_required
    assert_raises(ArgumentError) { Todo.new(id: nil, list_id: 'l1', title: 'Buy milk') }
    assert_raises(ArgumentError) { Todo.new(id: 'abc', list_id: nil, title: 'Buy milk') }
  end

  def test_it_belongs_to_a_list_and_keeps_it_through_changes
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk')

    assert_equal 'l1', todo.list_id
    assert_equal 'l1', todo.complete.tag('home').untag('home').list_id
  end

  def test_complete_returns_a_completed_copy_and_leaves_the_original_alone
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: ['home'])

    completed = todo.complete

    assert_predicate completed, :completed?
    assert_equal ['home'], completed.tags.map(&:name)
    refute_predicate todo, :completed?
  end

  def test_tags_are_normalised_deduplicated_and_sorted
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: 'urgent, #Home home')

    assert_equal %w[home urgent], todo.tags.map(&:name)
  end

  def test_tagged_asks_by_name_or_tag
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: ['home'])

    assert todo.tagged?('Home')
    assert todo.tagged?(Tag.new('home'))
    refute todo.tagged?('work')
  end

  def test_tag_returns_a_copy_with_the_tags_added
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: ['home'])

    tagged = todo.tag('urgent, home')

    assert_equal %w[home urgent], tagged.tags.map(&:name)
    assert_equal ['home'], todo.tags.map(&:name)
  end

  def test_untag_returns_a_copy_without_the_tag
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: %w[home urgent])

    assert_equal ['urgent'], todo.untag('#home').tags.map(&:name)
    assert_equal %w[home urgent], todo.untag('absent').tags.map(&:name)
  end

  def test_a_todo_can_have_at_most_five_tags
    todo = Todo.new(id: 'abc', list_id: 'l1', title: 'Busy', tags: %w[a b c d e])

    error = assert_raises(Todo::Invalid) { todo.tag('f') }

    assert_equal 'A todo can have at most 5 tags', error.message
  end

  def test_a_malformed_tag_is_invalid_input
    assert_raises(InvalidInput) { Todo.new(id: 'abc', list_id: 'l1', title: 'Buy milk', tags: 'not ok!') }
  end

  def test_validate_normalises_without_needing_an_id
    title, tags = Todo.validate(title: ' Buy milk ', tags: 'Home')

    assert_equal 'Buy milk', title
    assert_equal ['home'], tags.map(&:name)
  end

  def test_todos_with_the_same_state_are_equal
    assert_equal Todo.new(id: 'a', list_id: 'l1', title: 'x', tags: 'b'), Todo.new(id: 'a', list_id: 'l1', title: 'x', tags: ['b'])
    refute_equal Todo.new(id: 'a', list_id: 'l1', title: 'x'), Todo.new(id: 'a', list_id: 'l1', title: 'x').complete
    refute_equal Todo.new(id: 'a', list_id: 'l1', title: 'x'), Todo.new(id: 'a', list_id: 'l1', title: 'x', tags: 'b')
  end
end
