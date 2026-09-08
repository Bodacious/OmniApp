# frozen_string_literal: true

require 'test_helper'
require 'support/list_item_repository_contract'
require 'models/list_item'
require 'repositories/list_item_repository'
require 'persistence/memory/store'

##
# ListItemRepository over the in-memory store. The same contract runs
# against the SQL store in the Rails and Sinatra suites, and against
# the localStorage store in the browser app -- one repository
# implementation, proven interchangeable across every backend.
class MemoryStoreListItemRepositoryTest < Minitest::Test
  include ListItemRepositoryContract

  def repository
    @repository ||= ListItemRepository.new(Persistence::Memory::Store.new(entity_class: ListItem))
  end
end
