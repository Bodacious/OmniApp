# frozen_string_literal: true

require_relative 'invalid_input'

##
# A label on a todo, like "home" or "urgent". A value object: two tags
# with the same name are the same tag.
#
# Tags are written the way people type them ("#Home", " urgent ") and
# normalised to lowercase without the leading #. What's left must be
# letters, digits and single dashes, at most MAX_LENGTH long.
class Tag
  include Comparable

  class Invalid < InvalidInput; end

  MAX_LENGTH = 24
  FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  ##
  # The tags in free text ("home, #Urgent work") or an array of names or
  # Tags: split on commas and spaces, normalised, without duplicates,
  # sorted by name. Blank entries are skipped; a malformed one raises.
  def self.list(input)
    names = input.is_a?(Array) ? input : input.to_s.split(/[\s,]+/)
    names.reject { |name| name.to_s.strip.empty? }
         .map { |name| name.is_a?(Tag) ? name : Tag.new(name) }
         .uniq(&:name)
         .sort
  end

  attr_reader :name

  def initialize(name)
    @name = name.to_s.strip.sub(/\A#+/, '').downcase
    raise Invalid, "A tag can't be blank" if @name.empty?
    raise Invalid, "Tags can be at most #{MAX_LENGTH} characters" if @name.length > MAX_LENGTH
    raise Invalid, 'Tags can only use letters, numbers and dashes' unless FORMAT.match?(@name)
  end

  def <=>(other)
    name <=> other.name if other.is_a?(Tag)
  end

  def ==(other)
    other.is_a?(Tag) && other.name == name
  end
  alias eql? ==

  def hash
    name.hash
  end

  def to_s
    name
  end
end
