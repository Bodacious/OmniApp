# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'
require 'support/user_repository_contract'
require 'support/password_hasher_contract'
require 'support/in_memory_list_repository'
require 'support/in_memory_user_repository'
require 'support/fake_password_hasher'

##
# Runs the contracts against the domain's own test doubles, so the
# doubles behave as the real implementations do.
class InMemoryListRepositoryTest < ActiveSupport::TestCase
  include ListRepositoryContract

  def list_repository
    @list_repository ||= InMemoryListRepository.new
  end
end

class InMemoryUserRepositoryTest < ActiveSupport::TestCase
  include UserRepositoryContract

  def user_repository
    @user_repository ||= InMemoryUserRepository.new
  end
end

class FakePasswordHasherTest < ActiveSupport::TestCase
  include PasswordHasherContract

  def password_hasher
    @password_hasher ||= FakePasswordHasher.new
  end
end
