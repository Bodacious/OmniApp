# frozen_string_literal: true

require 'test_helper'
require 'todo_service'
require 'support/in_memory_todo_repository'
require 'support/sequential_id_generator'

class TodoServiceTest < Minitest::Test
  def setup
    @repository = InMemoryTodoRepository.new
    @ids = SequentialIdGenerator.new
    @service = TodoService.new(repository: @repository, id_generator: @ids)
  end

  def test_there_are_no_todos_to_begin_with
    assert_empty @service.todos
  end

  def test_add_stores_a_todo_with_a_generated_id
    todo = @service.add('Buy milk')

    assert_equal 'todo-1', todo.id
    assert_equal [todo], @service.todos
  end

  def test_add_stores_the_tags
    todo = @service.add('Buy milk', 'Errands, #home')

    assert_equal %w[errands home], @repository.find(todo.id).tags.map(&:name)
  end

  def test_add_rejects_a_blank_title_without_storing_anything_or_spending_an_id
    assert_raises(Todo::Invalid) { @service.add('  ') }
    assert_empty @service.todos
    assert_equal 'todo-1', @ids.next_id
  end

  def test_add_rejects_a_malformed_tag_without_storing_anything_or_spending_an_id
    assert_raises(Tag::Invalid) { @service.add('Buy milk', 'not ok!') }
    assert_empty @service.todos
    assert_equal 'todo-1', @ids.next_id
  end

  def test_complete_marks_the_todo_as_completed
    todo = @service.add('Buy milk')

    @service.complete(todo.id)

    assert_predicate @service.todos.first, :completed?
  end

  def test_complete_raises_not_found_for_an_unknown_todo
    assert_raises(TodoService::NotFound) { @service.complete('missing') }
  end

  def test_tag_adds_tags_to_a_todo
    todo = @service.add('Buy milk', 'home')

    @service.tag(todo.id, 'urgent')

    assert_equal %w[home urgent], @repository.find(todo.id).tags.map(&:name)
  end

  def test_tag_enforces_the_most_tags_a_todo_can_have
    todo = @service.add('Busy', 'a b c d e')

    assert_raises(Todo::Invalid) { @service.tag(todo.id, 'f') }
    assert_equal 5, @repository.find(todo.id).tags.size
  end

  def test_untag_removes_a_tag
    todo = @service.add('Buy milk', 'home urgent')

    @service.untag(todo.id, 'urgent')

    assert_equal ['home'], @repository.find(todo.id).tags.map(&:name)
  end

  def test_tag_and_untag_raise_not_found_for_an_unknown_todo
    assert_raises(TodoService::NotFound) { @service.tag('missing', 'home') }
    assert_raises(TodoService::NotFound) { @service.untag('missing', 'home') }
  end

  def test_todos_can_be_filtered_by_tag
    milk = @service.add('Buy milk', 'home')
    @service.add('File taxes', 'work')
    mum = @service.add('Call mum', 'Home')

    assert_equal [milk.id, mum.id], @service.todos(tagged: '#home').map(&:id)
    assert_equal 3, @service.todos(tagged: nil).size
    assert_equal 3, @service.todos(tagged: '').size
  end

  def test_filtering_by_a_malformed_tag_is_invalid_input
    assert_raises(InvalidInput) { @service.todos(tagged: 'not ok!') }
  end

  def test_tags_lists_each_tag_in_use_with_its_count
    @service.add('Buy milk', 'home errands')
    @service.add('Call mum', 'home')

    counts = @service.tags.map { |count| [count.tag.name, count.todo_count] }

    assert_equal [['errands', 1], ['home', 2]], counts
  end

  def test_delete_removes_the_todo
    keep = @service.add('Walk dog')
    gone = @service.add('Buy milk')

    @service.delete(gone.id)

    assert_equal [keep], @service.todos
  end

  def test_delete_raises_not_found_for_an_unknown_todo
    assert_raises(TodoService::NotFound) { @service.delete('missing') }
  end
end
