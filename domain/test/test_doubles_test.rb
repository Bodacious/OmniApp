# frozen_string_literal: true

require 'test_helper'
require 'support/todo_repository_contract'
require 'support/list_repository_contract'
require 'support/user_repository_contract'
require 'support/password_hasher_contract'
require 'support/in_memory_todo_repository'
require 'support/in_memory_list_repository'
require 'support/in_memory_user_repository'
require 'support/fake_password_hasher'

##
# Runs the port contracts against the domain's own test doubles, so the
# doubles the service tests use are known to behave like the real
# adapters do.
class InMemoryTodoRepositoryTest < Minitest::Test
  include TodoRepositoryContract

  def repository
    @repository ||= InMemoryTodoRepository.new
  end
end

class InMemoryListRepositoryTest < Minitest::Test
  include ListRepositoryContract

  def list_repository
    @list_repository ||= InMemoryListRepository.new
  end
end

class InMemoryUserRepositoryTest < Minitest::Test
  include UserRepositoryContract

  def user_repository
    @user_repository ||= InMemoryUserRepository.new
  end
end

class FakePasswordHasherTest < Minitest::Test
  include PasswordHasherContract

  def password_hasher
    @password_hasher ||= FakePasswordHasher.new
  end
end
