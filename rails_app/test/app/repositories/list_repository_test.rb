# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'

class ListRepositoryTest < Minitest::Test
  include ListRepositoryContract

  def repository
    @repository ||= ListRepository.new(DB)
  end
end
