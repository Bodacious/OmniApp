# frozen_string_literal: true

module Ports
  ##
  # The list repository port: how the domain stores lists. Synchronous,
  # like every port; ids come from the domain.
  #
  # The contract, checked for every adapter by
  # domain/test/support/list_repository_contract.rb:
  #
  # [owned_by(user_id)]
  #   Every List that user owns, in the order they were first saved.
  # [find(id)]
  #   The stored List with this id, or nil.
  # [save(list)]
  #   Stores +list+, replacing one with the same id. Returns +list+.
  # [delete(id)]
  #   Removes the list. Returns true if one was removed, false if not.
  #   (Its todos are TodoService's to remove, through the todo
  #   repository.)
  module ListRepository
    def owned_by(_user_id)
      raise NotImplementedError, "#{self.class} must implement #owned_by"
    end

    def find(_id)
      raise NotImplementedError, "#{self.class} must implement #find"
    end

    def save(_list)
      raise NotImplementedError, "#{self.class} must implement #save"
    end

    def delete(_id)
      raise NotImplementedError, "#{self.class} must implement #delete"
    end
  end
end
