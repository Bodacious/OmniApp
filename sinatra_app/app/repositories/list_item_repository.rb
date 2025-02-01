# frozen_string_literal: true

require "models/list_item"
class ListItemRepository
  def create(**attributes)
    list_item = ListItem.new(**attributes)
    list_item.id = 1
    list_item
  end

  def find(id)
    list_item = ListItem.new(**{})
    list_item.id = id
    list_item
  end
end
