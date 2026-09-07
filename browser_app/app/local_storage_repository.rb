# frozen_string_literal: true

require_relative 'local_storage_collection'

##
# A generic persistence backend backed by the browser's localStorage,
# for any domain entity with id/attributes/persisted? (see List,
# ListItem). Which entity class it loads, and which localStorage key
# it's stored under, are configuration passed to the constructor (or
# by a subclass via super) rather than hardcoded.
class LocalStorageRepository
  def initialize(entity_class:, storage_key:)
    @entity_class = entity_class
    @storage_key = storage_key
  end

  def save(entity)
    records = read
    entity.id = next_id(records) unless entity.persisted?
    records[entity.id.to_s] = entity.attributes
    write(records)
    entity
  end

  def find(id)
    record = read[id.to_s]
    record && entity_class.new(**record)
  end

  def all
    read.values.map { |attributes| entity_class.new(**attributes) }
  end

  def delete(id)
    records = read
    return false unless records.key?(id.to_s)

    records.delete(id.to_s)
    write(records)
    true
  end

  private

  attr_reader :entity_class, :storage_key

  def read
    LocalStorageCollection.read(storage_key)
  end

  def write(records)
    LocalStorageCollection.write(storage_key, records)
  end

  def next_id(records)
    records.keys.map(&:to_i).max.to_i + 1
  end
end
