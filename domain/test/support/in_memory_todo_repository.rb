# frozen_string_literal: true

require 'ports/todo_repository'

##
# A test double for the repository port: the simplest thing that
# satisfies the contract, so domain tests need no database.
class InMemoryTodoRepository
  include Ports::TodoRepository

  def initialize
    @todos = {}
  end

  def all
    @todos.values
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
