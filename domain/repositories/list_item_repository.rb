# frozen_string_literal: true

require_relative 'repository'
require 'models/list_item'

class ListItemRepository < Repository
  def initialize(database_connection)
    super(database_connection, entity_class: ListItem)
  end

  def all_for_list(list)
    data_source.where(list_id: list.id).all.map { entity_class.new(**_1) }
  end
end
