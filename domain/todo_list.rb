# frozen_string_literal: true

require_relative 'todo'
require_relative 'ports/todo_repository'
require_relative 'ports/id_generator'

##
# The use cases the domain offers: list the todos, add one, complete
# one, delete one. This is everything an app layer is allowed to ask of
# the domain; it never touches a repository or id generator directly.
#
# Both collaborators are ports (see domain/ports/) injected by an app's
# composition root. The domain doesn't know or care what's behind them.
class TodoList
  ##
  # Raised when a use case names a todo that doesn't exist.
  class NotFound < StandardError; end

  def initialize(repository:, id_generator:)
    @repository = repository
    @id_generator = id_generator
  end

  # All todos, oldest first.
  def todos
    repository.all
  end

  # Adds a todo with the given title and returns it. Raises
  # Todo::Invalid, without saving anything, if the title is blank.
  def add(title)
    todo = Todo.new(id: id_generator.next_id, title: title)
    repository.save(todo)
    todo
  end

  # Marks the todo as completed and returns it. Completing a todo that
  # is already completed is harmless.
  def complete(id)
    todo = find!(id).complete
    repository.save(todo)
    todo
  end

  # Deletes the todo. Raises NotFound if there's no such todo.
  def delete(id)
    find!(id)
    repository.delete(id)
    nil
  end

  private

  attr_reader :repository, :id_generator

  def find!(id)
    repository.find(id) || raise(NotFound, "No todo with id #{id}")
  end
end
