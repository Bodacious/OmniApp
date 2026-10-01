# frozen_string_literal: true

require_relative 'invalid_input'

##
# A named list of todos, owned by one user. Only its owner may see it
# or change anything in it; TodoService enforces that.
class List
  class Invalid < InvalidInput; end

  MAX_NAME_LENGTH = 60

  # The name as a list stores it (stripped), or Invalid.
  def self.normalize_name(name)
    name = name.to_s.strip
    raise Invalid, "Name can't be blank" if name.empty?
    raise Invalid, "Names can be at most #{MAX_NAME_LENGTH} characters" if name.length > MAX_NAME_LENGTH

    name
  end

  attr_reader :id, :owner_id, :name

  def initialize(id:, owner_id:, name:)
    raise ArgumentError, 'A list needs an id' if id.nil? || id.to_s.empty?
    raise ArgumentError, 'A list needs an owner' if owner_id.nil? || owner_id.to_s.empty?

    @id = id.to_s
    @owner_id = owner_id.to_s
    @name = List.normalize_name(name)
  end

  def owned_by?(user)
    !user.nil? && user.id == owner_id
  end

  def ==(other)
    other.is_a?(List) && other.id == id && other.owner_id == owner_id && other.name == name
  end
end
