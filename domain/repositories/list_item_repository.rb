# frozen_string_literal: true

##
# List items, as the domain talks about them. Names the query the
# domain cares about -- the items belonging to a list -- and delegates
# the mechanics to an injected store, so this one class serves every
# backend rather than needing a subclass per backend.
#
# The store is anything satisfying the store API: save, find, all,
# delete, find_by(**criteria), where(**criteria), delete_by(**criteria).
# See persistence/ for the implementations.
class ListItemRepository
  def initialize(store)
    @store = store
  end

  def save(list_item)
    store.save(list_item)
  end

  def find(id)
    store.find(id)
  end

  def all_for_list(list)
    store.where(list_id: list.id)
  end

  def delete(id)
    store.delete(id)
  end

  private

  attr_reader :store
end
