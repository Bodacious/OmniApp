# frozen_string_literal: true

require 'model/user_repository'

##
# A UserRepository kept in a Hash, with predictable ids: the simplest
# thing that satisfies the contract, so domain tests need no database.
class InMemoryUserRepository
  include UserRepository

  def initialize
    @users = {}
    @last_id = 0
  end

  def next_identity
    @last_id += 1
    "user-#{@last_id}"
  end

  def find(id)
    @users[id.to_s]
  end

  def find_by_email(email)
    @users.values.find { |user| user.email == email }
  end

  def save(user)
    @users[user.id] = user
    user
  end
end
