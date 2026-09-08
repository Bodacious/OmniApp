# frozen_string_literal: true

require 'test_helper'
require 'support/list_item_repository_contract'

##
# The same ListItemRepository the domain suite exercises over the
# in-memory store, here over the SQL store.
class SqlStoreListItemRepositoryTest < Minitest::Test
  include ListItemRepositoryContract

  def repository
    @repository ||= ListItemRepository.new(
      Persistence::Sql::Store.new(DB, table: :list_items, entity_class: ListItem)
    )
  end
end
