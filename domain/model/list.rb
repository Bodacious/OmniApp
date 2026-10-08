# frozen_string_literal: true

require_relative 'invalid_input'
require_relative 'not_found'
require_relative 'tag'
require_relative 'todo'

##
# A named list of todos, owned by one user: the aggregate root for
# todos. A Todo exists only on its List, is found only through it, and
# is stored and removed with it (see ListRepository), so the list is
# where the rules about its todos hold.
#
# Changes are made in memory; nothing is stored until the list is
# saved to its repository.
class List
  class Invalid < InvalidInput; end

  ##
  # A tag in use on a list, and how many of its todos carry it.
  TagCount = Struct.new(:tag, :todo_count)

  MAX_NAME_LENGTH = 60

  # The name as a list stores it (stripped).
  #
  # @param name [String, nil]
  # @return [String]
  # @raise [Invalid] if it's blank or too long
  def self.normalize_name(name)
    name = name.to_s.strip
    raise Invalid, "Name can't be blank" if name.empty?
    raise Invalid, "Names can be at most #{MAX_NAME_LENGTH} characters" if name.length > MAX_NAME_LENGTH

    name
  end

  attr_reader :id, :owner_id, :name

  # @param id [String] from ListRepository#next_identity
  # @param owner_id [String] the id of the User who owns it
  # @param name [String, nil]
  # @param todos [Array<Todo>] oldest first
  # @raise [ArgumentError] without an id or an owner
  # @raise [Invalid] for a blank or long name
  def initialize(id:, owner_id:, name:, todos: [])
    raise ArgumentError, 'A list needs an id' if id.nil? || id.to_s.empty?
    raise ArgumentError, 'A list needs an owner' if owner_id.nil? || owner_id.to_s.empty?

    @id = id.to_s
    @owner_id = owner_id.to_s
    @name = List.normalize_name(name)
    @todos = todos.to_a.dup
  end

  # @param user [User, nil]
  # @return [Boolean]
  def owned_by?(user)
    !user.nil? && user.id == owner_id
  end

  # The list's todos, oldest first; only those with the tag, if one is
  # given.
  #
  # @param tagged [String, Tag, nil]
  # @return [Array<Todo>]
  # @raise [InvalidInput] if +tagged+ isn't a valid tag
  def todos(tagged: nil)
    return @todos.dup if tagged.nil? || tagged.to_s.empty?

    tag = Tag.new(tagged)
    @todos.select { |todo| todo.tagged?(tag) }
  end

  # Every tag in use on this list, by name, with how many todos carry it.
  #
  # @return [Array<TagCount>]
  def tags
    counts = Hash.new(0)
    @todos.each { |todo| todo.tags.each { |tag| counts[tag.name] += 1 } }
    counts.keys.sort.map { |name| TagCount.new(Tag.new(name), counts[name]) }
  end

  # The todo on this list with this id.
  #
  # @param todo_id [String]
  # @return [Todo]
  # @raise [NotFound] if it isn't on this list
  def todo(todo_id)
    @todos.find { |todo| todo.id == todo_id.to_s } || raise(NotFound, 'No such todo')
  end

  # Adds a todo, newest last.
  #
  # @param id [String] from ListRepository#next_identity
  # @param title [String, nil]
  # @param tags [String, Array<String, Tag>] free text ("home, urgent") or a list
  # @return [Todo]
  # @raise [InvalidInput] having added nothing, if the title or tags break the model's rules
  def add(id:, title:, tags: [])
    todo = Todo.new(id: id, title: title, tags: tags)
    raise ArgumentError, "This list already has a todo #{todo.id}" if @todos.any? { |existing| existing.id == todo.id }

    @todos << todo
    todo
  end

  # Marks a todo as completed. Completing it twice is harmless.
  #
  # @param todo_id [String]
  # @return [Todo]
  # @raise [NotFound]
  def complete(todo_id)
    current = todo(todo_id)
    @todos[@todos.index(current)] = current.complete
  end

  # Adds tags to a todo.
  #
  # @param todo_id [String]
  # @param tags [String, Array<String, Tag>]
  # @return [Todo]
  # @raise [NotFound]
  # @raise [InvalidInput] for a malformed tag, or if the todo would have too many
  def tag(todo_id, tags)
    current = todo(todo_id)
    @todos[@todos.index(current)] = current.tag(tags)
  end

  # Removes a tag from a todo.
  #
  # @param todo_id [String]
  # @param tag [String, Tag]
  # @return [Todo]
  # @raise [NotFound]
  def untag(todo_id, tag)
    current = todo(todo_id)
    @todos[@todos.index(current)] = current.untag(tag)
  end

  # Takes a todo off the list.
  #
  # @param todo_id [String]
  # @return [nil]
  # @raise [NotFound]
  def remove(todo_id)
    @todos.delete(todo(todo_id))
    nil
  end

  def ==(other)
    other.is_a?(List) && other.id == id && other.owner_id == owner_id && other.name == name &&
      other.todos == todos
  end
end
