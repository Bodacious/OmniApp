# frozen_string_literal: true

require 'models/list_item'
require_relative '../local_storage_repository'

##
# A ListItem persistence backend backed by the browser's localStorage.
# Satisfies the same contract as any other ListItem repository (see
# ListItemRepositoryContract in domain/test/support): save,
# all_for_list, delete.
class LocalStorageListItemRepository < LocalStorageRepository
  def initialize
    super(entity_class: ListItem, storage_key: 'omniapp.list_items')
  end

  def all_for_list(list)
    read.values
        .select { |attributes| attributes['list_id'] == list.id }
        .map { |attributes| entity_class.new(**attributes) }
  end
end
