# frozen_string_literal: true

require_relative 'invalid_input'

##
# Someone with an account. Users own lists.
#
# A User holds a digest of its password, never the password itself.
# Making and checking digests is the PasswordHasher port's job (see
# domain/ports/), so the model needs no cryptography.
class User
  class Invalid < InvalidInput; end

  EMAIL = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  MIN_PASSWORD_LENGTH = 8

  # The email as accounts store it (stripped, lowercase), or Invalid.
  def self.normalize_email(email)
    email = email.to_s.strip.downcase
    raise Invalid, 'Enter a valid email address' unless EMAIL.match?(email)

    email
  end

  # The password, if it's acceptable for a new account, or Invalid.
  def self.check_password(password)
    password = password.to_s
    if password.length < MIN_PASSWORD_LENGTH
      raise Invalid, "Passwords must be at least #{MIN_PASSWORD_LENGTH} characters"
    end

    password
  end

  attr_reader :id, :email, :password_digest

  def initialize(id:, email:, password_digest:)
    raise ArgumentError, 'A user needs an id' if id.nil? || id.to_s.empty?
    raise ArgumentError, 'A user needs a password digest' if password_digest.nil? || password_digest.to_s.empty?

    @id = id.to_s
    @email = User.normalize_email(email)
    @password_digest = password_digest.to_s
  end

  def ==(other)
    other.is_a?(User) && other.id == id && other.email == email && other.password_digest == password_digest
  end
end
