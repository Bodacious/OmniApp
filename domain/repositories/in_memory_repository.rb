# frozen_string_literal: true

##
# A generic in-memory persistence backend for any domain entity with
# id/attributes/persisted? (see List, ListItem). No database required:
# everything lives in a plain Hash for the life of the process. Which
# entity class it loads is configuration, passed to the constructor
# (or by a subclass via super) rather than hardcoded.
class InMemoryRepository
  def initialize(entity_class:)
    @entity_class = entity_class
    @records = {}
    @next_id = 1
  end

  def save(entity)
    if entity.persisted?
      records[entity.id] = entity.attributes.dup
    else
      entity.id = next_id
      records[entity.id] = entity.attributes.dup
      self.next_id += 1
    end
    entity
  end

  def find(id)
    record = records[id]
    record && entity_class.new(**record)
  end

  def all
    records.values.map { |attributes| entity_class.new(**attributes) }
  end

  def delete(id)
    return false unless records.key?(id)

    records.delete(id)
    true
  end

  private

  attr_reader :entity_class, :records
  attr_accessor :next_id
end
