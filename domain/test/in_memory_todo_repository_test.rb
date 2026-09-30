# frozen_string_literal: true

require 'test_helper'
require 'support/todo_repository_contract'
require 'support/in_memory_todo_repository'

##
# Runs the repository contract against the domain's own test double,
# so the double used by TodoListTest is known to behave like the real
# adapters do.
class InMemoryTodoRepositoryTest < Minitest::Test
  include TodoRepositoryContract

  def repository
    @repository ||= InMemoryTodoRepository.new
  end
end
