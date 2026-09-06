# frozen_string_literal: true

require 'models/list'
require_relative '../local_storage_collection'

##
# A List persistence backend backed by the browser's localStorage.
# Satisfies the same contract as any other List repository (see
# ListRepositoryContract in domain/test/support): save, find,
# find_by_slug, all, delete_by_slug.
class LocalStorageListRepository
  STORAGE_KEY = 'omniapp.lists'

  def save(list)
    records = read
    list.id = next_id(records) unless list.persisted?
    records[list.id.to_s] = list.attributes
    write(records)
    list
  end

  def find(id)
    record = read[id.to_s]
    record && List.new(**record)
  end

  def find_by_slug(slug)
    record = read.values.find { |attributes| attributes['slug'] == slug }
    record && List.new(**record)
  end

  def all
    read.values.map { |attributes| List.new(**attributes) }
  end

  def delete_by_slug(slug)
    records = read
    id = records.find { |_id, attributes| attributes['slug'] == slug }&.first
    return false unless id

    records.delete(id)
    write(records)
    true
  end

  private

  def read
    LocalStorageCollection.read(STORAGE_KEY)
  end

  def write(records)
    LocalStorageCollection.write(STORAGE_KEY, records)
  end

  def next_id(records)
    records.keys.map(&:to_i).max.to_i + 1
  end
end
