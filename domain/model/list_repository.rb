# frozen_string_literal: true

require_relative 'list'
require_relative 'not_found'

##
# Every List there is, todos and all: the repository for the list
# aggregate. There is no repository for todos, because a Todo is part
# of its List: it is loaded with the list, saved with it and removed
# with it.
#
# The domain defines it as a collection, in the model's own terms, and
# infrastructure implements the storage underneath. Implementations
# include this module and override the storage methods, which are
# synchronous and return their results directly. The contract, checked
# for each one by domain/test/support/list_repository_contract.rb:
#
# [next_identity]
#   A new id, for a List or one of its Todos, never returned before
#   and safe in a URL. Ids come from the repository, not from a
#   database sequence, so a list or todo has its identity before it's
#   stored.
# [find(id)]
#   The stored List with this id, with its todos, or nil.
# [owned_by(user)]
#   Every List that User owns, in the order they were first saved.
# [save(list)]
#   Stores +list+ as it is now: its name, and exactly its todos, in
#   order, each with its completed state and tags. Replaces a list with
#   the same id, and its todos keep their place. Returns +list+.
# [remove(list)]
#   Removes the list and every todo on it. Returns nil.
#
# Lists come back exactly as they were saved, and are copies: changing
# one changes nothing stored until it is saved. How an implementation
# stores todos and tags (tables, a Hash) is its own business.
#
# On top of those, this module gives every implementation the
# ownership rule (#fetch).
module ListRepository
  # @return [String]
  def next_identity
    raise NotImplementedError, "#{self.class} must implement #next_identity"
  end

  # @param _id [String]
  # @return [List, nil]
  def find(_id)
    raise NotImplementedError, "#{self.class} must implement #find"
  end

  # @param _user [User]
  # @return [Array<List>]
  def owned_by(_user)
    raise NotImplementedError, "#{self.class} must implement #owned_by"
  end

  # @param _list [List]
  # @return [List]
  def save(_list)
    raise NotImplementedError, "#{self.class} must implement #save"
  end

  # @param _list [List]
  # @return [nil]
  def remove(_list)
    raise NotImplementedError, "#{self.class} must implement #remove"
  end

  # One of +owner+'s lists. A list that belongs to someone else is
  # reported exactly like one that doesn't exist.
  #
  # @param id [String, nil]
  # @param owner [User]
  # @return [List]
  # @raise [NotFound] if there's no such list, or it isn't theirs
  def fetch(id, owner:)
    list = find(id.to_s)
    raise NotFound, 'No such list' unless list&.owned_by?(owner)

    list
  end
end
