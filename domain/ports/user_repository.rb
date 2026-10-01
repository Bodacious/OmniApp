# frozen_string_literal: true

module Ports
  ##
  # The user repository port: how the domain stores accounts.
  # Synchronous, like every port; ids come from the domain.
  #
  # The contract, checked for every adapter by
  # domain/test/support/user_repository_contract.rb:
  #
  # [find(id)]
  #   The stored User with this id, or nil.
  # [find_by_email(email)]
  #   The stored User with this email, or nil. Emails arrive already
  #   normalised by User, so an exact match is right.
  # [save(user)]
  #   Stores +user+, replacing one with the same id. Returns +user+.
  module UserRepository
    def find(_id)
      raise NotImplementedError, "#{self.class} must implement #find"
    end

    def find_by_email(_email)
      raise NotImplementedError, "#{self.class} must implement #find_by_email"
    end

    def save(_user)
      raise NotImplementedError, "#{self.class} must implement #save"
    end
  end
end
