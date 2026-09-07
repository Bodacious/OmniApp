# frozen_string_literal: true

require 'models/list_item'
require_relative 'in_memory_repository'

##
# In-memory ListItem persistence. Satisfies the same contract as any
# other ListItem repository (see ListItemRepositoryContract in
# domain/test/support): save, all_for_list, delete.
class InMemoryListItemRepository < InMemoryRepository
  def initialize
    super(entity_class: ListItem)
  end

  def all_for_list(list)
    records.values
           .select { |attributes| attributes[:list_id] == list.id }
           .map { |attributes| entity_class.new(**attributes) }
  end
end
