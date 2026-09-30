# frozen_string_literal: true

module Ports
  ##
  # The repository port: how the domain stores todos. The domain
  # defines it; persistence adapters implement it by including this
  # module and overriding every method.
  #
  # The port is synchronous. Every method returns its result directly,
  # never a promise or callback, so the same domain code runs unchanged
  # whether the adapter talks to SQLite through Sequel under MRI or to
  # Postgres through pg-native under Node.
  #
  # Adapters must not generate ids: every todo arrives with its id
  # already set (see Ports::IdGenerator).
  #
  # The contract, checked for every adapter by
  # domain/test/support/todo_repository_contract.rb:
  #
  # [all]
  #   Every stored Todo as an Array, in the order they were first
  #   saved. An empty Array when there are none.
  # [find(id)]
  #   The stored Todo with this id, or nil.
  # [save(todo)]
  #   Stores +todo+. If a todo with the same id is already stored, it
  #   is replaced and keeps its place in #all. Returns +todo+.
  # [delete(id)]
  #   Removes the todo with this id. Returns true if one was removed,
  #   false if there was none.
  module TodoRepository
    def all
      raise NotImplementedError, "#{self.class} must implement #all"
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
