# frozen_string_literal: true

require_relative 'user'

##
# Every User there is: the repository for the account aggregate. The
# domain defines it as a collection, in the model's own terms, and
# infrastructure implements the storage underneath.
#
# Implementations include this module and override the storage
# methods, which are synchronous and return their results directly.
# The contract, checked for each one by
# domain/test/support/user_repository_contract.rb:
#
# [next_identity]
#   A new id for a User, never returned before and safe in a URL. Ids
#   come from the repository, not from a database sequence, so a User
#   has its identity before it's stored.
# [find(id)]
#   The stored User with this id, or nil (also for a nil id).
# [find_by_email(email)]
#   The stored User with this email, or nil. Emails arrive already
#   normalised by User, so an exact match is right.
# [save(user)]
#   Stores +user+, replacing one with the same id. Returns +user+.
#
# On top of those, this module gives every implementation the rules
# that hold across the whole collection: one account per email (#add),
# and signing in as anyone unknown failing the same way (#account_for).
module UserRepository
  # @return [String]
  def next_identity
    raise NotImplementedError, "#{self.class} must implement #next_identity"
  end

  # @param _id [String, nil]
  # @return [User, nil]
  def find(_id)
    raise NotImplementedError, "#{self.class} must implement #find"
  end

  # @param _email [String]
  # @return [User, nil]
  def find_by_email(_email)
    raise NotImplementedError, "#{self.class} must implement #find_by_email"
  end

  # @param _user [User]
  # @return [User]
  def save(_user)
    raise NotImplementedError, "#{self.class} must implement #save"
  end

  # Adds a newly registered user to the collection.
  #
  # @param user [User]
  # @return [User]
  # @raise [User::Invalid] having stored nothing, if the email already has an account
  def add(user)
    raise User::Invalid, 'That email already has an account' if find_by_email(user.email)

    save(user)
  end

  # Whoever +email+ belongs to, ready to authenticate: the stored User,
  # or User::NOBODY for an email that is unknown or malformed.
  #
  # @param email [String, nil]
  # @return [User, User::Nobody]
  def account_for(email)
    find_by_email(User.normalize_email(email)) || User::NOBODY
  rescue User::Invalid
    User::NOBODY
  end
end
