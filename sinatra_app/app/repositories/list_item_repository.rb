# frozen_string_literal: true

require "models/list_item"

class ListItemRepository < Repository
  def save_list_item_to_list(list_slug:, list_item:)
    DB.run(<<~SQL)
      INSERT INTO list_items (#{list_item.attributes.keys.join(',')}, list_id)
      SELECT #{list_item.attributes.values.map(&:inspect).join(",")}, id
      FROM lists
      WHERE slug = '#{list_slug}'
    SQL
    list_item
  rescue Sequel
    return false
  end

  def all_for_list(list)
    data_source.where(list_id: list.id).all.map { ListItem.new(_1) }
  end

  def find(id)
    list_item = ListItem.new(**{})
    list_item.id = id
    list_item
  end

  def delete_list_item(list_slug:, id:)
    # TODO: Filter this by list_slug
    data_source.where(id: id).delete
  rescue Sequel
    return false
  end
end
