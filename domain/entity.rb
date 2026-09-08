# frozen_string_literal: true

##
# The structural contract a domain entity must satisfy to be stored by
# any persistence backend (see persistence/). Deliberately minimal: a
# store needs to read an entity's persistable state, know whether it
# has been stored yet, and assign an identity after an insert. It
# needs nothing else, and in particular nothing specific to any one
# entity.
#
# Including classes must provide:
#
# [attributes]
#   Hash of the entity's persistable state, including :id once stored.
# [id]
#   The entity's identity, or nil when it hasn't been stored yet.
# [id=]
#   Assigns the identity, called by a store after an insert.
#
# and must be constructible from that same attributes hash, so a store
# can rehydrate an entity from a stored record.
module Entity
  def persisted?
    !id.nil?
  end
end
