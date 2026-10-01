# frozen_string_literal: true

module Ports
  ##
  # The todo repository port: how the domain stores todos. The domain
  # defines it; persistence adapters implement it by including this
  # module and overriding every method.
  #
  # Like every port here it is synchronous. Every method returns its
  # result directly, never a promise or callback, so the same domain
  # code runs unchanged whether an adapter talks to SQLite through
  # Sequel under MRI or to Postgres through pg-native under Node.
  #
  # Adapters must not generate ids: every todo arrives with its id
  # already set (see Ports::IdGenerator).
  #
  # The contract, checked for every adapter by
  # domain/test/support/todo_repository_contract.rb:
  #
  # [in_list(list_id)]
  #   Every stored Todo on that list, as an Array, in the order they
  #   were first saved. An empty Array when there are none.
  # [find(id)]
  #   The stored Todo with this id, or nil.
  # [save(todo)]
  #   Stores +todo+, with its tags. If a todo with the same id is
  #   already stored, it is replaced, tags and all, and keeps its place.
  #   Returns +todo+.
  # [delete(id)]
  #   Removes the todo, and its tags. Returns true if one was removed,
  #   false if there was none.
  #
  # Todos come back exactly as they were saved: same id, list, title,
  # completed state and tags. How an adapter stores tags (a join table,
  # a column, a Hash) is its own business.
  module TodoRepository
    def in_list(_list_id)
      raise NotImplementedError, "#{self.class} must implement #in_list"
    end

    def find(_id)
      raise NotImplementedError, "#{self.class} must implement #find"
    end

    def save(_todo)
      raise NotImplementedError, "#{self.class} must implement #save"
    end

    def delete(_id)
      raise NotImplementedError, "#{self.class} must implement #delete"
    end
  end
end
