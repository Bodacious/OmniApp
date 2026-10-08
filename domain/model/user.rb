# frozen_string_literal: true

require_relative 'invalid_input'

##
# Someone with an account; the aggregate root for accounts. Users own
# lists.
#
# A User holds a digest of its password, never the password itself.
# Making and checking digests is a PasswordHasher's job, so the model
# needs no cryptography.
class User
  class Invalid < InvalidInput; end

  ##
  # Raised when an email and password don't match an account. The
  # message deliberately doesn't say which was wrong.
  class SignInFailed < InvalidInput; end

  EMAIL = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  MIN_PASSWORD_LENGTH = 8
  SIGN_IN_FAILED = 'Email or password is incorrect'

  ##
  # Stands in for an account that doesn't exist, so that signing in as
  # a stranger fails exactly as a wrong password does.
  class Nobody
    # @raise [SignInFailed] always
    def authenticate(_password, _hasher)
      raise SignInFailed, SIGN_IN_FAILED
    end
  end

  NOBODY = Nobody.new.freeze

  # The email as accounts store it (stripped, lowercase).
  #
  # @param email [String, nil]
  # @return [String]
  # @raise [Invalid] if it isn't an email address
  def self.normalize_email(email)
    email = email.to_s.strip.downcase
    raise Invalid, 'Enter a valid email address' unless EMAIL.match?(email)

    email
  end

  # The password, if it's acceptable for a new account.
  #
  # @param password [String, nil]
  # @return [String]
  # @raise [Invalid] if it's too short
  def self.check_password(password)
    password = password.to_s
    if password.length < MIN_PASSWORD_LENGTH
      raise Invalid, "Passwords must be at least #{MIN_PASSWORD_LENGTH} characters"
    end

    password
  end

  # A new account, keeping only a digest of its password.
  #
  # @param id [String] from UserRepository#next_identity
  # @param email [String, nil]
  # @param password [String, nil]
  # @param hasher [PasswordHasher]
  # @return [User]
  # @raise [Invalid] for a malformed email or a short password
  def self.register(id:, email:, password:, hasher:)
    email = normalize_email(email)
    new(id: id, email: email, password_digest: hasher.digest(check_password(password)))
  end

  attr_reader :id, :email, :password_digest

  # @param id [String]
  # @param email [String]
  # @param password_digest [String]
  # @raise [ArgumentError] without an id or a digest
  # @raise [Invalid] for a malformed email
  def initialize(id:, email:, password_digest:)
    raise ArgumentError, 'A user needs an id' if id.nil? || id.to_s.empty?
    raise ArgumentError, 'A user needs a password digest' if password_digest.nil? || password_digest.to_s.empty?

    @id = id.to_s
    @email = User.normalize_email(email)
    @password_digest = password_digest.to_s
  end

  # This user, if +password+ is theirs.
  #
  # @param password [String, nil]
  # @param hasher [PasswordHasher]
  # @return [User]
  # @raise [SignInFailed] if it isn't
  def authenticate(password, hasher)
    raise SignInFailed, SIGN_IN_FAILED unless hasher.matches?(password.to_s, password_digest)

    self
  end

  def ==(other)
    other.is_a?(User) && other.id == id && other.email == email && other.password_digest == password_digest
  end
end
