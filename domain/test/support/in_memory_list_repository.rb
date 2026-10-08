# frozen_string_literal: true

require 'model/list_repository'

##
# A ListRepository kept in a Hash, with predictable ids: the simplest
# thing that satisfies the contract, so domain tests need no database.
# It keeps copies, as a database would, so a list changed and not
# saved stays as it was.
class InMemoryListRepository
  include ListRepository

  def initialize
    @lists = {}
    @last_id = 0
  end

  def next_identity
    @last_id += 1
    "id-#{@last_id}"
  end

  def find(id)
    stored = @lists[id.to_s]
    stored && copy_of(stored)
  end

  def owned_by(user)
    @lists.values.select { |list| list.owned_by?(user) }.map { |list| copy_of(list) }
  end

  def save(list)
    @lists[list.id] = copy_of(list)
    list
  end

  def remove(list)
    @lists.delete(list.id)
    nil
  end

  private

  # Todos never change in place, so a new List around them is a copy.
  def copy_of(list)
    List.new(id: list.id, owner_id: list.owner_id, name: list.name, todos: list.todos)
  end
end
