# frozen_string_literal: true

require 'models/list_item'

##
# An in-memory ListItem persistence backend, mirroring
# InMemoryListRepository. No database required: everything lives in a
# plain Hash for the life of the process.
class InMemoryListItemRepository
  def initialize
    @records = {}
    @next_id = 1
  end

  def save(list_item)
    if list_item.persisted?
      @records[list_item.id] = list_item.attributes.dup
    else
      list_item.id = @next_id
      @records[list_item.id] = list_item.attributes.dup
      @next_id += 1
    end
    list_item
  end

  def all_for_list(list)
    @records.values
            .select { |attributes| attributes[:list_id] == list.id }
            .map { |attributes| ListItem.new(attributes) }
  end

  def delete(id)
    return false unless @records.key?(id)

    @records.delete(id)
    true
  end
end
