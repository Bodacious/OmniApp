# frozen_string_literal: true

require_relative 'invalid_input'
require_relative 'tag'

##
# A single thing to do: the model's entity. A value object in practice:
# every change returns a new Todo rather than altering this one, which
# keeps it safe to share and behaves the same under MRI and Opal.
#
# The rules a todo enforces about itself:
# - it has a title (stripped, so whitespace alone doesn't count);
# - its tags are valid Tags (see Tag), with no duplicates, and there
#   are at most MAX_TAGS of them.
#
# A Todo depends on nothing outside domain/model/. In particular it
# never loads or saves itself: that's TodoService's job, through the
# repository port.
class Todo
  class Invalid < InvalidInput; end

  BLANK_TITLE = "Title can't be blank"
  MAX_TAGS = 5

  ##
  # The title and tags as a todo would store them, or Invalid if they
  # break its rules. Lets TodoService check input before it spends an id.
  def self.validate(title:, tags: [])
    title = title.to_s.strip
    raise Invalid, BLANK_TITLE if title.empty?

    tags = Tag.list(tags)
    raise Invalid, "A todo can have at most #{MAX_TAGS} tags" if tags.size > MAX_TAGS

    [title, tags]
  end

  attr_reader :id, :title, :tags

  def initialize(id:, title:, completed: false, tags: [])
    raise ArgumentError, 'A todo needs an id' if id.nil? || id.to_s.empty?

    @id = id.to_s
    @title, @tags = Todo.validate(title: title, tags: tags)
    @tags.freeze
    @completed = completed ? true : false
  end

  def completed?
    @completed
  end

  def tagged?(tag)
    tags.include?(tag.is_a?(Tag) ? tag : Tag.new(tag))
  end

  def complete
    copy(completed: true)
  end

  # A copy with these tags added. Raises Invalid if that would make too
  # many.
  def tag(new_tags)
    copy(tags: tags + Tag.list(new_tags))
  end

  # A copy without this tag. Removing a tag it doesn't have is harmless.
  def untag(tag)
    tag = Tag.new(tag) unless tag.is_a?(Tag)
    copy(tags: tags.reject { |existing| existing == tag })
  end

  def ==(other)
    other.is_a?(Todo) &&
      other.id == id &&
      other.title == title &&
      other.completed? == completed? &&
      other.tags == tags
  end

  private

  def copy(completed: completed?, tags: self.tags)
    Todo.new(id: id, title: title, completed: completed, tags: tags)
  end
end
