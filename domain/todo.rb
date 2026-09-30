# frozen_string_literal: true

##
# A single thing to do. A value object: completing a todo returns a new
# Todo rather than changing this one, which keeps it safe to share and
# behaves the same under MRI and Opal.
#
# The one rule a todo enforces about itself is that it has a title.
# The title is stripped, so whitespace alone doesn't count.
class Todo
  ##
  # Raised when a todo would break one of its own rules. The message is
  # written for the person who typed the title, so apps can show it.
  class Invalid < StandardError; end

  BLANK_TITLE = "Title can't be blank"

  attr_reader :id, :title

  def initialize(id:, title:, completed: false)
    raise ArgumentError, 'A todo needs an id' if id.nil? || id.to_s.empty?

    @id = id.to_s
    @title = title.to_s.strip
    @completed = completed ? true : false
    raise Invalid, BLANK_TITLE if @title.empty?
  end

  def completed?
    @completed
  end

  def complete
    Todo.new(id: id, title: title, completed: true)
  end

  def ==(other)
    other.is_a?(Todo) &&
      other.id == id &&
      other.title == title &&
      other.completed? == completed?
  end
end
