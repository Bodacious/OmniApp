# frozen_string_literal: true

require 'test_helper'
require 'model/list'
require 'model/user'

class ListTest < ActiveSupport::TestCase
  test '.new strips the name' do
    assert_equal 'Groceries', List.new(id: 'l1', owner_id: 'u1', name: '  Groceries ').name
  end

  test '.new when the name is blank raises Invalid' do
    error = assert_raises(List::Invalid) { List.new(id: 'l1', owner_id: 'u1', name: '  ') }

    assert_equal "Name can't be blank", error.message
  end

  test '.new without an id raises ArgumentError' do
    assert_raises(ArgumentError) { List.new(id: '', owner_id: 'u1', name: 'Groceries') }
  end

  test '.new without an owner raises ArgumentError' do
    assert_raises(ArgumentError) { List.new(id: 'l1', owner_id: nil, name: 'Groceries') }
  end

  test '.normalize_name when the name is too long raises Invalid' do
    assert_raises(List::Invalid) { List.normalize_name('x' * 61) }
  end

  test '#owned_by? when the user is the owner is true' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_operator list, :owned_by?, User.new(id: 'u1', email: 'ada@example.com', password_digest: 'd')
  end

  test '#owned_by? when the user is someone else is false' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_not_operator list, :owned_by?, User.new(id: 'u2', email: 'bob@example.com', password_digest: 'd')
  end

  test '#owned_by? when there is no user is false' do
    assert_not_operator List.new(id: 'l1', owner_id: 'u1', name: 'Groceries'), :owned_by?, nil
  end

  test '#add puts a todo at the end of the list and returns it' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Walk dog')

    todo = list.add(id: 't2', title: ' Buy milk ', tags: 'Errands, #home')

    assert_equal [list.todo('t1'), todo], list.todos
  end

  test '#add normalises the title and tags' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    todo = list.add(id: 't1', title: ' Buy milk ', tags: 'Errands, #home')

    assert_equal ['Buy milk', %w[errands home]], [todo.title, todo.tags.map(&:name)]
  end

  test '#add when the title is blank raises Invalid and adds nothing' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(Todo::Invalid) { list.add(id: 't1', title: '  ') }
    assert_empty list.todos
  end

  test '#add when a tag is malformed raises Invalid and adds nothing' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(Tag::Invalid) { list.add(id: 't1', title: 'Buy milk', tags: 'not ok!') }
    assert_empty list.todos
  end

  test '#add when the id is already on the list raises ArgumentError' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk')

    assert_raises(ArgumentError) { list.add(id: 't1', title: 'Walk dog') }
  end

  test '#todo when the todo is on the list returns it' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries', todos: [Todo.new(id: 't1', title: 'Buy milk')])

    assert_equal Todo.new(id: 't1', title: 'Buy milk'), list.todo('t1')
  end

  test '#todo when the todo is not on the list raises NotFound' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    error = assert_raises(NotFound) { list.todo('elsewhere') }

    assert_equal 'No such todo', error.message
  end

  test '#todos with a tag returns only the todos carrying it' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk', tags: 'home errands')
    list.add(id: 't2', title: 'File taxes', tags: 'work')
    list.add(id: 't3', title: 'Call mum', tags: 'Home')

    assert_equal %w[t1 t3], list.todos(tagged: '#home').map(&:id)
  end

  test '#todos with an empty tag returns every todo' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk', tags: 'home')
    list.add(id: 't2', title: 'File taxes')

    assert_equal 2, list.todos(tagged: '').size
  end

  test '#todos with a malformed tag raises Invalid' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(Tag::Invalid) { list.todos(tagged: 'not ok!') }
  end

  test '#todos returns a copy that does not change the list' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    list.todos << Todo.new(id: 't1', title: 'Sneaky')

    assert_empty list.todos
  end

  test '#tags counts the todos carrying each tag, by name' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk', tags: 'home errands')
    list.add(id: 't2', title: 'File taxes', tags: 'work')
    list.add(id: 't3', title: 'Call mum', tags: 'home')

    counts = list.tags.map { |count| [count.tag.name, count.todo_count] }

    assert_equal [['errands', 1], ['home', 2], ['work', 1]], counts
  end

  test '#complete marks the todo as completed' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk')

    list.complete('t1')

    assert_predicate list.todo('t1'), :completed?
  end

  test '#complete returns the completed todo' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk')

    assert_predicate list.complete('t1'), :completed?
  end

  test '#complete keeps the todo in its place' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    %w[t1 t2 t3].each { |id| list.add(id: id, title: id) }

    list.complete('t2')

    assert_equal %w[t1 t2 t3], list.todos.map(&:id)
  end

  test '#complete when the todo is not on the list raises NotFound' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(NotFound) { list.complete('elsewhere') }
  end

  test '#tag adds the tags to the todo' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk', tags: 'home')

    list.tag('t1', 'urgent, home')

    assert_equal %w[home urgent], list.todo('t1').tags.map(&:name)
  end

  test '#tag when the todo would have too many tags raises Invalid and changes nothing' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Busy', tags: 'a b c d e')

    assert_raises(Todo::Invalid) { list.tag('t1', 'f') }
    assert_equal 5, list.todo('t1').tags.size
  end

  test '#tag when the todo is not on the list raises NotFound' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(NotFound) { list.tag('elsewhere', 'home') }
  end

  test '#untag removes the tag from the todo' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Buy milk', tags: 'home urgent')

    list.untag('t1', '#home')

    assert_equal ['urgent'], list.todo('t1').tags.map(&:name)
  end

  test '#untag when the todo is not on the list raises NotFound' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(NotFound) { list.untag('elsewhere', 'home') }
  end

  test '#remove takes the todo off the list' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')
    list.add(id: 't1', title: 'Walk dog')
    list.add(id: 't2', title: 'Buy milk')

    list.remove('t2')

    assert_equal ['t1'], list.todos.map(&:id)
  end

  test '#remove when the todo is not on the list raises NotFound' do
    list = List.new(id: 'l1', owner_id: 'u1', name: 'Groceries')

    assert_raises(NotFound) { list.remove('elsewhere') }
  end

  test '#== when the lists have the same state and todos is true' do
    assert_equal List.new(id: 'l1', owner_id: 'u1', name: 'Groceries', todos: [Todo.new(id: 't1', title: 'x')]),
                 List.new(id: 'l1', owner_id: 'u1', name: 'Groceries', todos: [Todo.new(id: 't1', title: 'x')])
  end

  test '#== when the todos differ is false' do
    assert_not_equal List.new(id: 'l1', owner_id: 'u1', name: 'Groceries'),
                     List.new(id: 'l1', owner_id: 'u1', name: 'Groceries', todos: [Todo.new(id: 't1', title: 'x')])
  end
end
