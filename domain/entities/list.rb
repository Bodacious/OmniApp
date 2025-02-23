# frozen_string_literal: true

require "forwardable"
require_relative "list/item"
##
# A List is a single place to store a group of related tasks or reminders
class List
  # Stores all of the items in a given List
  class ListItemSet
    extend Forwardable
    attr_reader :set

    def_delegator :set, :delete, :remove
    def_delegators :set, :add, :include?, :empty?, :select

    def initialize
      @set = Set.new
    end
  end

  ##
  # Name of the list
  # @return [String]
  attr_reader :name

  ##
  # List of items in this List
  # @return [ListItemSet]
  attr_accessor :items
  private :items=

  def initialize(**attributes)
    @name = attributes[:name]
    @items = ListItemSet.new
  end

  # Add an item to this list
  # @param [List::Item] item
  def add_item(item)
    items.add(item)
  end

  # Remove an item from this list
  # @param [List::Item] item
  def remove_item(item)
    items.remove(item)
  end

  def refresh
    new_items = ListItemSet.new
    pending_items.each { |item| new_items.add(item) }
    repeatable_items.each { |item| new_items.add(item.dup) }
    self.items = new_items
  end

  def pending_items
    items.select(&:pending?)
  end

  private

  def repeatable_items
    items.select(&:repeatable?)
  end
end
