# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'
require 'models/list'
require 'repositories/list_repository'
require 'persistence/memory/store'

##
# ListRepository over the in-memory store. The same contract runs
# against the SQL store in the Rails and Sinatra suites, and against
# the localStorage store in the browser app -- one repository
# implementation, proven interchangeable across every backend.
class MemoryStoreListRepositoryTest < Minitest::Test
  include ListRepositoryContract

  def repository
    @repository ||= ListRepository.new(Persistence::Memory::Store.new(entity_class: List))
  end
end
