# frozen_string_literal: true

##
# Lists, as the domain talks about them. Names the queries the domain
# cares about -- by slug -- and delegates the mechanics to an injected
# store, so this one class serves every backend rather than needing a
# subclass per backend.
#
# The store is anything satisfying the store API: save, find, all,
# delete, find_by(**criteria), where(**criteria), delete_by(**criteria).
# See persistence/ for the implementations.
class ListRepository
  def initialize(store)
    @store = store
  end

  def save(list)
    store.save(list)
  end

  def find(id)
    store.find(id)
  end

  def all
    store.all
  end

  def delete(id)
    store.delete(id)
  end

  def find_by_slug(slug)
    store.find_by(slug: slug)
  end

  def delete_by_slug(slug)
    store.delete_by(slug: slug)
  end

  private

  attr_reader :store
end
