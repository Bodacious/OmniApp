# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'

##
# The same ListRepository the domain suite exercises over the
# in-memory store, here over the SQL store.
class SqlStoreListRepositoryTest < Minitest::Test
  include ListRepositoryContract

  def repository
    @repository ||= ListRepository.new(
      Persistence::Sql::Store.new(DATABASE, table: :lists, entity_class: List)
    )
  end
end
