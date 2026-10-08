# frozen_string_literal: true

require 'model/password_hasher'

##
# A PasswordHasher for tests: fast, salted and
# obviously not secure. Domain tests use it so they need no OpenSSL.
class FakePasswordHasher
  include PasswordHasher

  def initialize
    @salt = 0
  end

  def digest(password)
    @salt += 1
    "fake$#{@salt}$#{password.unpack1('H*')}"
  end

  def matches?(password, digest)
    _scheme, _salt, hex = digest.to_s.split('$', 3)
    hex == password.unpack1('H*')
  end
end
