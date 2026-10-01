# frozen_string_literal: true

require 'ports/password_hasher'

##
# A test double for the password hasher port: fast, salted and
# obviously not secure. Domain tests use it so they need no OpenSSL.
class FakePasswordHasher
  include Ports::PasswordHasher

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
