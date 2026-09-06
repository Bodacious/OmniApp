# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'
require 'repositories/in_memory_list_repository'

class InMemoryListRepositoryTest < Minitest::Test
  include ListRepositoryContract

  def repository
    @repository ||= InMemoryListRepository.new
  end
end
