# frozen_string_literal: true

require 'ports/user_repository'

##
# A test double for the user repository port.
class InMemoryUserRepository
  include Ports::UserRepository

  def initialize
    @users = {}
  end

  def find(id)
    @users[id]
  end

  def find_by_email(email)
    @users.values.find { |user| user.email == email }
  end

  def save(user)
    @users[user.id] = user
    user
  end
end
