# frozen_string_literal: true

require_relative 'model/todo'
require_relative 'ports/todo_repository'
require_relative 'ports/id_generator'

##
# The application's use cases: everything an app layer may ask of the
# domain. List and filter todos, add, complete, delete, tag and untag
# them. This is the driving side of the hexagon: every app layer calls
# these methods and nothing else in domain/.
#
# It's a service, not a model. The model (domain/model/) is Todo and
# Tag, which depend on nothing. The service coordinates the model with
# the outside world through ports (domain/ports/), interfaces the domain
# defines itself: the repository and the id generator. An app's
# composition root injects adapters for them; the service never learns
# what's behind them.
class TodoService
  ##
  # Raised when a use case names a todo that doesn't exist.
  class NotFound < StandardError; end

  ##
  # A tag in use, and how many todos carry it.
  TagCount = Struct.new(:tag, :todo_count)

  def initialize(repository:, id_generator:)
    @repository = repository
    @id_generator = id_generator
  end

  # All todos, oldest first; only those with the tag, if one is given.
  # Raises InvalidInput if +tagged+ isn't a valid tag.
  def todos(tagged: nil)
    all = repository.all
    return all if tagged.nil? || tagged.to_s.empty?

    tag = Tag.new(tagged)
    all.select { |todo| todo.tagged?(tag) }
  end

  # Every tag in use, by name, with how many todos carry it.
  def tags
    counts = Hash.new(0)
    repository.all.each { |todo| todo.tags.each { |tag| counts[tag.name] += 1 } }
    counts.keys.sort.map { |name| TagCount.new(Tag.new(name), counts[name]) }
  end

  # Adds a todo and returns it. +tags+ is free text ("home, urgent") or
  # a list. Raises InvalidInput, having saved nothing and generated no
  # id, if the title or tags break the model's rules.
  def add(title, tags = [])
    title, tags = Todo.validate(title: title, tags: tags)
    todo = Todo.new(id: id_generator.next_id, title: title, tags: tags)
    repository.save(todo)
    todo
  end

  # Marks the todo as completed. Completing it twice is harmless.
  def complete(id)
    change(id, &:complete)
  end

  # Adds tags (free text or a list) to the todo. Raises InvalidInput if
  # a tag is malformed or the todo would have too many.
  def tag(id, tags)
    change(id) { |todo| todo.tag(tags) }
  end

  # Removes a tag from the todo.
  def untag(id, tag)
    change(id) { |todo| todo.untag(tag) }
  end

  # Deletes the todo. Raises NotFound if there's no such todo.
  def delete(id)
    find!(id)
    repository.delete(id)
    nil
  end

  private

  attr_reader :repository, :id_generator

  def change(id)
    todo = yield find!(id)
    repository.save(todo)
    todo
  end

  def find!(id)
    repository.find(id) || raise(NotFound, "No todo with id #{id}")
  end
end
