# frozen_string_literal: true

require 'models/list_item'
require_relative '../local_storage_collection'

##
# A ListItem persistence backend backed by the browser's localStorage.
# Satisfies the same contract as any other ListItem repository (see
# ListItemRepositoryContract in domain/test/support): save,
# all_for_list, delete.
class LocalStorageListItemRepository
  STORAGE_KEY = 'omniapp.list_items'

  def save(list_item)
    records = read
    list_item.id = next_id(records) unless list_item.persisted?
    records[list_item.id.to_s] = list_item.attributes
    write(records)
    list_item
  end

  def all_for_list(list)
    read.values
        .select { |attributes| attributes['list_id'] == list.id }
        .map { |attributes| ListItem.new(attributes) }
  end

  def delete(id)
    records = read
    return false unless records.key?(id.to_s)

    records.delete(id.to_s)
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
