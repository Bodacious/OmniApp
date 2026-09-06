# frozen_string_literal: true

require 'test_helper'
require 'support/list_item_repository_contract'
require 'repositories/in_memory_list_item_repository'

class InMemoryListItemRepositoryTest < Minitest::Test
  include ListItemRepositoryContract

  def repository
    @repository ||= InMemoryListItemRepository.new
  end
end
