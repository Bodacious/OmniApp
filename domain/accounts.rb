# frozen_string_literal: true

require_relative 'model/user'
require_relative 'ports/user_repository'
require_relative 'ports/password_hasher'
require_relative 'ports/id_generator'

##
# The account use cases: signing up and signing in. Like TodoService
# it's an application service: the model (User) holds the rules, and
# the outside world (storage, password hashing, ids) is reached only
# through ports the domain defines.
#
# Sessions aren't here. Remembering who is signed in between requests
# is each app layer's business (a Rails session, a signed cookie); the
# domain only answers "who is this?" and "are these credentials right?"
class Accounts
  ##
  # Raised when an email and password don't match an account. The
  # message deliberately doesn't say which was wrong.
  class SignInFailed < InvalidInput; end

  SIGN_IN_FAILED = 'Email or password is incorrect'

  def initialize(users:, password_hasher:, id_generator:)
    @users = users
    @password_hasher = password_hasher
    @id_generator = id_generator
  end

  # Creates an account and returns its User. Raises InvalidInput, having
  # stored nothing, for a malformed email, a short password or an email
  # that already has an account.
  def sign_up(email:, password:)
    email = User.normalize_email(email)
    password = User.check_password(password)
    raise User::Invalid, 'That email already has an account' if users.find_by_email(email)

    user = User.new(id: id_generator.next_id, email: email, password_digest: password_hasher.digest(password))
    users.save(user)
    user
  end

  # The User these credentials belong to. Raises SignInFailed otherwise.
  def sign_in(email:, password:)
    user = begin
      users.find_by_email(User.normalize_email(email))
    rescue User::Invalid
      nil
    end
    raise SignInFailed, SIGN_IN_FAILED unless user && password_hasher.matches?(password.to_s, user.password_digest)

    user
  end

  # The User with this id, or nil: for an app restoring a session.
  def find(id)
    id.nil? || id.to_s.empty? ? nil : users.find(id.to_s)
  end

  private

  attr_reader :users, :password_hasher, :id_generator
end
