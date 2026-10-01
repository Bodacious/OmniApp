# frozen_string_literal: true

require_relative 'model/user'
require_relative 'model/list'
require_relative 'model/todo'
require_relative 'ports/list_repository'
require_relative 'ports/todo_repository'
require_relative 'ports/id_generator'

##
# The application's use cases for lists and todos: everything an app
# layer may ask of the domain once someone has signed in (see Accounts
# for signing in). This is the driving side of the hexagon.
#
# Every use case is performed by a User, and users own lists: a user
# can see and change only their own. A list that belongs to someone
# else is reported as NotFound, exactly like one that doesn't exist, so
# ids reveal nothing.
#
# It's a service, not a model. The model (domain/model/) is User, List,
# Todo and Tag, which depend on nothing. The service coordinates them
# with the outside world through ports (domain/ports/) that the domain
# defines; an app's composition root injects adapters for them.
class TodoService
  ##
  # Raised when a use case names a list or todo that doesn't exist, or
  # that the user doesn't own.
  class NotFound < StandardError; end

  ##
  # A tag in use on a list, and how many of its todos carry it.
  TagCount = Struct.new(:tag, :todo_count)

  def initialize(lists:, todos:, id_generator:)
    @lists = lists
    @todos = todos
    @id_generator = id_generator
  end

  # The user's lists, oldest first.
  def lists(user)
    @lists.owned_by(user.id)
  end

  # Creates a list for the user and returns it. Raises InvalidInput,
  # having stored nothing, if the name is blank or too long.
  def create_list(user, name)
    name = List.normalize_name(name)
    list = List.new(id: @id_generator.next_id, owner_id: user.id, name: name)
    @lists.save(list)
    list
  end

  # Deletes one of the user's lists and every todo on it.
  def delete_list(user, list_id)
    list = owned_list(user, list_id)
    @todos.in_list(list.id).each { |todo| @todos.delete(todo.id) }
    @lists.delete(list.id)
    nil
  end

  # One of the user's lists, with the use cases for its todos. Raises
  # NotFound if there's no such list or it's someone else's.
  def list(user, list_id)
    UserList.new(owned_list(user, list_id), todos: @todos, id_generator: @id_generator)
  end

  ##
  # The use cases on the todos of one list, which its owner has opened.
  # Todos are found only within this list, so an id from another list
  # (anyone's) is NotFound.
  class UserList
    attr_reader :list

    def initialize(list, todos:, id_generator:)
      @list = list
      @todos = todos
      @id_generator = id_generator
    end

    def id
      list.id
    end

    def name
      list.name
    end

    # The list's todos, oldest first; only those with the tag, if one is
    # given. Raises InvalidInput if +tagged+ isn't a valid tag.
    def todos(tagged: nil)
      all = @todos.in_list(list.id)
      return all if tagged.nil? || tagged.to_s.empty?

      tag = Tag.new(tagged)
      all.select { |todo| todo.tagged?(tag) }
    end

    # Every tag in use on this list, by name, with how many todos carry it.
    def tags
      counts = Hash.new(0)
      @todos.in_list(list.id).each { |todo| todo.tags.each { |tag| counts[tag.name] += 1 } }
      counts.keys.sort.map { |name| TagCount.new(Tag.new(name), counts[name]) }
    end

    # Adds a todo and returns it. +tags+ is free text ("home, urgent") or
    # a list. Raises InvalidInput, having saved nothing and generated no
    # id, if the title or tags break the model's rules.
    def add(title, tags = [])
      title, tags = Todo.validate(title: title, tags: tags)
      todo = Todo.new(id: @id_generator.next_id, list_id: list.id, title: title, tags: tags)
      @todos.save(todo)
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

    # Deletes the todo.
    def delete(id)
      find!(id)
      @todos.delete(id)
      nil
    end

    private

    def change(id)
      todo = yield find!(id)
      @todos.save(todo)
      todo
    end

    def find!(id)
      todo = @todos.find(id)
      raise NotFound, 'No such todo' unless todo && todo.list_id == list.id

      todo
    end
  end

  private

  def owned_list(user, list_id)
    list = @lists.find(list_id.to_s)
    raise NotFound, 'No such list' unless list&.owned_by?(user)

    list
  end
end
