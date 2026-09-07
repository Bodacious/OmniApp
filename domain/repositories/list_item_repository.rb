# frozen_string_literal: true

require 'models/list_item'

##
# Satisfies the same contract as any other ListItem repository (see
# ListItemRepositoryContract in domain/test/support): save,
# all_for_list, delete. Also provides find, which callers use to
# verify an item actually belongs to a particular list before acting
# on it.
class ListItemRepository < Repository
  def save(list_item)
    if list_item.persisted?
      data_source.where(id: list_item.id).update(**list_item.attributes.except(:id))
    else
      list_item.id = insert(**list_item.attributes)
    end
    list_item
  end

  def find(id)
    result = data_source.where(id: id).first
    result && ListItem.new(result)
  end

  def all_for_list(list)
    data_source.where(list_id: list.id).all.map { ListItem.new(_1) }
  end

  def delete(id)
    data_source.where(id: id).delete.positive?
  end
end
