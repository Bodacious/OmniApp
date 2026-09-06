# frozen_string_literal: true

require 'models/list'

##
# An in-memory List persistence backend: no database required. Useful
# for tests, demos, and anywhere a real database isn't available.
#
# Satisfies the same contract as any other List repository (see
# ListRepositoryContract in domain/test/support): save, find,
# find_by_slug, all, delete_by_slug.
#
# Each instance owns its own private store and nothing is shared
# between instances, so use a single shared instance per process
# rather than creating a new one per request.
class InMemoryListRepository
  def initialize
    @records = {}
    @next_id = 1
  end

  def save(list)
    if list.persisted?
      @records[list.id] = list.attributes.dup
    else
      list.id = @next_id
      @records[list.id] = list.attributes.dup
      @next_id += 1
    end
    list
  end

  def find(id)
    record = @records[id]
    record && List.new(**record)
  end

  def find_by_slug(slug)
    record = @records.values.find { |attributes| attributes[:slug] == slug }
    record && List.new(**record)
  end

  def all
    @records.values.map { |attributes| List.new(**attributes) }
  end

  def delete_by_slug(slug)
    id = @records.find { |_id, attributes| attributes[:slug] == slug }&.first
    return false unless id

    @records.delete(id)
    true
  end
end
