# frozen_string_literal: true

##
# The behaviour every PasswordHasher implementation must provide (see
# domain/model/password_hasher.rb). Include it into a Minitest::Test
# that defines +password_hasher+.
module PasswordHasherContract
  PASSWORD = 'correct horse battery'

  def test_password_hasher_is_a_password_hasher
    assert_kind_of PasswordHasher, password_hasher
  end

  def test_a_digest_is_a_string_without_the_password_in_it
    digest = password_hasher.digest(PASSWORD)

    assert_kind_of String, digest
    refute_includes digest, PASSWORD
  end

  def test_digests_are_salted
    refute_equal password_hasher.digest(PASSWORD), password_hasher.digest(PASSWORD)
  end

  def test_the_right_password_matches
    assert password_hasher.matches?(PASSWORD, password_hasher.digest(PASSWORD))
  end

  def test_a_wrong_password_does_not_match
    refute password_hasher.matches?('wrong horse battery', password_hasher.digest(PASSWORD))
  end

  def test_an_unreadable_digest_does_not_match
    refute password_hasher.matches?(PASSWORD, 'not a digest')
  end
end
