# frozen_string_literal: true

require_relative "list/item"
##
# A List is a single place to store a group of related tasks or reminders
class List
  attr_reader :name
  attr_accessor :items

  def initialize(**attributes)
    @name = attributes[:name]
    @items = Set.new
  end

  def add_item(item)
    items.add(item)
  end
end
