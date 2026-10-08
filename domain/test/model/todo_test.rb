# frozen_string_literal: true

require 'test_helper'
require 'model/todo'

class TodoTest < ActiveSupport::TestCase
  test '.new is not completed by default' do
    assert_not_predicate Todo.new(id: 'abc', title: 'Buy milk'), :completed?
  end

  test '.new is untagged by default' do
    assert_empty Todo.new(id: 'abc', title: 'Buy milk').tags
  end

  test '.new strips the title' do
    assert_equal 'Buy milk', Todo.new(id: 'abc', title: "  Buy milk \n").title
  end

  test '.new when the title is blank raises Invalid' do
    ['', '   ', "\n\t", nil].each do |title|
      error = assert_raises(Todo::Invalid) { Todo.new(id: 'abc', title: title) }

      assert_equal "Title can't be blank", error.message
    end
  end

  test '.new without an id raises ArgumentError' do
    assert_raises(ArgumentError) { Todo.new(id: nil, title: 'Buy milk') }
  end

  test '.new normalises, deduplicates and sorts the tags' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', tags: 'urgent, #Home home')

    assert_equal %w[home urgent], todo.tags.map(&:name)
  end

  test '.new when a tag is malformed raises InvalidInput' do
    assert_raises(InvalidInput) { Todo.new(id: 'abc', title: 'Buy milk', tags: 'not ok!') }
  end

  test '.new when there are more than five tags raises Invalid' do
    error = assert_raises(Todo::Invalid) { Todo.new(id: 'abc', title: 'Busy', tags: %w[a b c d e f]) }

    assert_equal 'A todo can have at most 5 tags', error.message
  end

  test '#tagged? when given a name it carries is true' do
    assert_operator Todo.new(id: 'abc', title: 'Buy milk', tags: ['home']), :tagged?, 'Home'
  end

  test '#tagged? when given a Tag it carries is true' do
    assert_operator Todo.new(id: 'abc', title: 'Buy milk', tags: ['home']), :tagged?, Tag.new('home')
  end

  test '#tagged? when given a tag it lacks is false' do
    assert_not_operator Todo.new(id: 'abc', title: 'Buy milk', tags: ['home']), :tagged?, 'work'
  end

  test '#complete returns a completed copy with the same tags' do
    completed = Todo.new(id: 'abc', title: 'Buy milk', tags: ['home']).complete

    assert_equal Todo.new(id: 'abc', title: 'Buy milk', tags: ['home'], completed: true), completed
  end

  test '#complete leaves the original alone' do
    todo = Todo.new(id: 'abc', title: 'Buy milk')

    todo.complete

    assert_not_predicate todo, :completed?
  end

  test '#tag returns a copy with the tags added' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', tags: ['home'])

    assert_equal %w[home urgent], todo.tag('urgent, home').tags.map(&:name)
  end

  test '#tag leaves the original alone' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', tags: ['home'])

    todo.tag('urgent')

    assert_equal ['home'], todo.tags.map(&:name)
  end

  test '#tag keeps the completed state' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', completed: true)

    assert_predicate todo.tag('home'), :completed?
  end

  test '#tag when that would make more than five tags raises Invalid' do
    todo = Todo.new(id: 'abc', title: 'Busy', tags: %w[a b c d e])

    assert_raises(Todo::Invalid) { todo.tag('f') }
  end

  test '#untag returns a copy without the tag' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', tags: %w[home urgent])

    assert_equal ['urgent'], todo.untag('#home').tags.map(&:name)
  end

  test '#untag when the todo lacks the tag changes nothing' do
    todo = Todo.new(id: 'abc', title: 'Buy milk', tags: %w[home urgent])

    assert_equal todo, todo.untag('absent')
  end

  test '#== when the id, title, completed state and tags are the same is true' do
    assert_equal Todo.new(id: 'a', title: 'x', tags: 'b'), Todo.new(id: 'a', title: 'x', tags: ['b'])
  end

  test '#== when the completed state differs is false' do
    assert_not_equal Todo.new(id: 'a', title: 'x'), Todo.new(id: 'a', title: 'x').complete
  end
end
