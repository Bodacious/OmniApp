# frozen_string_literal: true

module Ports
  ##
  # The id generator port: where new todos get their identity. The
  # domain assigns ids itself, before anything is stored, so identity
  # never depends on a database sequence and every persistence adapter
  # treats ids the same way.
  #
  # Adapters implement it by including this module and overriding:
  #
  # [next_id]
  #   A new, non-empty String, never returned before. It must be safe to
  #   put in a URL path segment.
  module IdGenerator
    def next_id
      raise NotImplementedError, "#{self.class} must implement #next_id"
    end
  end
end
