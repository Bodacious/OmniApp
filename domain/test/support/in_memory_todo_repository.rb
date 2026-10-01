# frozen_string_literal: true

require 'ports/todo_repository'

##
# A test double for the todo repository port: the simplest thing that
# satisfies the contract, so domain tests need no database.
class InMemoryTodoRepository
  include Ports::TodoRepository

  def initialize
    @todos = {}
  end

  def in_list(list_id)
    @todos.values.select { |todo| todo.list_id == list_id }
  end

  def find(id)
    @todos[id]
  end

  def save(todo)
    @todos[todo.id] = todo
    todo
  end

  def delete(id)
    !@todos.delete(id).nil?
  end
end
