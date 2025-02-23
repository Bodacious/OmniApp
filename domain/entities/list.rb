# frozen_string_literal: true

require "forwardable"
require_relative 'list/item_set'
require_relative "list/item"
##
# A List is a single place to store a group of related tasks or reminders
class List
  # Stores all of the items in a given List

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
    new_items = List::ItemSet.new
    pending_items.each { |item| new_items.add(item) }
    repeatable_items.each { |item| new_items.add(item.dup) }
    old_items = self.items
    old_items.clear
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
