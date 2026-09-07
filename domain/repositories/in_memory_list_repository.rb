# frozen_string_literal: true

require 'models/list'
require_relative 'in_memory_repository'

##
# In-memory List persistence. Satisfies the same contract as any other
# List repository (see ListRepositoryContract in domain/test/support):
# save, find, find_by_slug, all, delete_by_slug.
class InMemoryListRepository < InMemoryRepository
  def initialize
    super(entity_class: List)
  end

  def find_by_slug(slug)
    record = records.values.find { |attributes| attributes[:slug] == slug }
    record && entity_class.new(**record)
  end

  def delete_by_slug(slug)
    id = records.find { |_id, attributes| attributes[:slug] == slug }&.first
    return false unless id

    records.delete(id)
    true
  end
end
