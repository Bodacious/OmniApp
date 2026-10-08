# frozen_string_literal: true

require_relative 'invalid_input'
require_relative 'tag'

##
# A single thing to do: an entity inside a List, reached only through
# its list. Every change returns a new Todo rather than altering this
# one, which keeps it safe to share and behaves the same under MRI and
# Opal; the List keeps whichever is current.
#
# The rules a todo enforces about itself:
# - it has a title (stripped, so whitespace alone doesn't count);
# - its tags are valid Tags (see Tag), with no duplicates, and there
#   are at most MAX_TAGS of them.
class Todo
  class Invalid < InvalidInput; end

  BLANK_TITLE = "Title can't be blank"
  MAX_TAGS = 5

  attr_reader :id, :title, :tags

  # @param id [String]
  # @param title [String, nil]
  # @param completed [Boolean]
  # @param tags [String, Array<String, Tag>] free text ("home, urgent") or a list
  # @raise [ArgumentError] without an id
  # @raise [InvalidInput] for a blank title, a malformed tag or too many tags
  def initialize(id:, title:, completed: false, tags: [])
    raise ArgumentError, 'A todo needs an id' if id.nil? || id.to_s.empty?

    @id = id.to_s
    @title = title.to_s.strip
    raise Invalid, BLANK_TITLE if @title.empty?

    @tags = Tag.list(tags).freeze
    raise Invalid, "A todo can have at most #{MAX_TAGS} tags" if @tags.size > MAX_TAGS

    @completed = completed ? true : false
  end

  def completed?
    @completed
  end

  # @param tag [String, Tag]
  # @return [Boolean]
  def tagged?(tag)
    tags.include?(tag.is_a?(Tag) ? tag : Tag.new(tag))
  end

  # @return [Todo] a completed copy
  def complete
    Todo.new(id: id, title: title, completed: true, tags: tags)
  end

  # A copy with these tags added.
  #
  # @param new_tags [String, Array<String, Tag>]
  # @return [Todo]
  # @raise [InvalidInput] for a malformed tag, or if that would make too many
  def tag(new_tags)
    Todo.new(id: id, title: title, completed: completed?, tags: tags + Tag.list(new_tags))
  end

  # A copy without this tag. Removing a tag it doesn't have is harmless.
  #
  # @param tag [String, Tag]
  # @return [Todo]
  def untag(tag)
    tag = Tag.new(tag) unless tag.is_a?(Tag)
    Todo.new(id: id, title: title, completed: completed?, tags: tags.reject { |existing| existing == tag })
  end

  def ==(other)
    other.is_a?(Todo) &&
      other.id == id &&
      other.title == title &&
      other.completed? == completed? &&
      other.tags == tags
  end
end
