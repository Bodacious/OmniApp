# frozen_string_literal: true
require 'forwardable'

class List
  class ItemSet < DelegateClass(Set)
    alias remove delete
    def initialize
      super(Set.new)
    end
  end
end
