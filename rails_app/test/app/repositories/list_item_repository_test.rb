# frozen_string_literal: true

require 'test_helper'
require 'support/list_item_repository_contract'

class ListItemRepositoryTest < Minitest::Test
  include ListItemRepositoryContract

  def repository
    @repository ||= ListItemRepository.new(DB)
  end
end
