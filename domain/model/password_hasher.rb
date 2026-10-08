# frozen_string_literal: true

##
# What a User needs to keep a password safe: a way to turn it into a
# digest, and to check a password against one. Cryptography differs
# by runtime (OpenSSL under MRI, node:crypto under Node), so the model
# names the need and infrastructure provides it.
#
# Implementations include this module and override both methods. The
# contract, checked for each one by
# domain/test/support/password_hasher_contract.rb:
#
# [digest(password)]
#   A String that doesn't contain the password and is different every
#   time (salted), even for the same password.
# [matches?(password, digest)]
#   True if +digest+ was made from +password+, false otherwise,
#   including for a digest it can't read.
module PasswordHasher
  # @param _password [String]
  # @return [String]
  def digest(_password)
    raise NotImplementedError, "#{self.class} must implement #digest"
  end

  # @param _password [String]
  # @param _digest [String]
  # @return [Boolean]
  def matches?(_password, _digest)
    raise NotImplementedError, "#{self.class} must implement #matches?"
  end
end
