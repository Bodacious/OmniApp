# frozen_string_literal: true

require "forwardable"
require_relative 'list/item_set'
require_relative "list/item"
##
# A List is a single place to store a group of related tasks or reminders
class List
  extend Forwardable

  def_delegators :items, :pending_items, :repeatable_items

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
    @items = List::ItemSet.new
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
    self.items = items.refresh
  end
end
