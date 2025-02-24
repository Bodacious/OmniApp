# frozen_string_literal: true
require 'forwardable'

class List
  # A set of List::Items that belong to a given List
  class ItemSet < DelegateClass(Set)
    alias remove delete
    def initialize
      super(Set.new)
    end

    def refresh
      new_set = self.class.new
      new_set.merge((pending_items | repeatable_items).map(&:refresh))

      clear # help in memory cleanup
      new_set
    end

    def pending_items
      select(&:pending?)
    end

    def repeatable_items
      select(&:repeatable?)
    end
  end
end
