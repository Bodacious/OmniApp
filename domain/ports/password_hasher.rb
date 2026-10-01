# frozen_string_literal: true

module Ports
  ##
  # The password hasher port: turns a password into a digest that's
  # safe to store, and checks a password against one. Cryptography is
  # infrastructure, so the domain names what it needs and adapters
  # provide it (OpenSSL under MRI, node:crypto under Node).
  #
  # The contract, checked for every adapter by
  # domain/test/support/password_hasher_contract.rb:
  #
  # [digest(password)]
  #   A String that doesn't contain the password and is different every
  #   time (salted), even for the same password.
  # [matches?(password, digest)]
  #   True if +digest+ was made from +password+, false otherwise,
  #   including for a digest it can't read.
  module PasswordHasher
    def digest(_password)
      raise NotImplementedError, "#{self.class} must implement #digest"
    end

    def matches?(_password, _digest)
      raise NotImplementedError, "#{self.class} must implement #matches?"
    end
  end
end
