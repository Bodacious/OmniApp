# frozen_string_literal: true

require 'test_helper'
require 'model/user'

class UserTest < Minitest::Test
  def test_it_has_an_id_an_email_and_a_password_digest
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')

    assert_equal 'u1', user.id
    assert_equal 'ada@example.com', user.email
    assert_equal 'digest', user.password_digest
  end

  def test_emails_are_normalised
    assert_equal 'ada@example.com', User.normalize_email('  Ada@Example.COM ')
  end

  def test_malformed_emails_are_invalid
    ['', 'ada', 'ada@', '@example.com', 'ada@example', 'a da@example.com'].each do |email|
      error = assert_raises(User::Invalid) { User.normalize_email(email) }

      assert_equal 'Enter a valid email address', error.message
    end
  end

  def test_passwords_must_be_at_least_eight_characters
    assert_equal 'eight ch', User.check_password('eight ch')

    error = assert_raises(User::Invalid) { User.check_password('seven c') }

    assert_equal 'Passwords must be at least 8 characters', error.message
  end

  def test_an_id_and_a_digest_are_required
    assert_raises(ArgumentError) { User.new(id: nil, email: 'ada@example.com', password_digest: 'd') }
    assert_raises(ArgumentError) { User.new(id: 'u1', email: 'ada@example.com', password_digest: '') }
  end
end
