# frozen_string_literal: true

##
# Raised when something is asked for by an id that names nothing the
# asker may see: a missing list, someone else's list, or a todo that
# isn't on the list. All three read the same, so ids reveal nothing.
class NotFound < StandardError; end
