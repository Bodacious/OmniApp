# frozen_string_literal: true

require 'test_helper'
require 'model/user'

class UserTest < ActiveSupport::TestCase
  test '.normalize_email strips and lowercases the email' do
    assert_equal 'ada@example.com', User.normalize_email('  Ada@Example.COM ')
  end

  test '.normalize_email when the email is malformed raises Invalid' do
    ['', 'ada', 'ada@', '@example.com', 'ada@example', 'a da@example.com', nil].each do |email|
      error = assert_raises(User::Invalid) { User.normalize_email(email) }

      assert_equal 'Enter a valid email address', error.message
    end
  end

  test '.check_password when the password has eight characters returns it' do
    assert_equal 'eight ch', User.check_password('eight ch')
  end

  test '.check_password when the password is shorter raises Invalid' do
    error = assert_raises(User::Invalid) { User.check_password('seven c') }

    assert_equal 'Passwords must be at least 8 characters', error.message
  end

  test '.register keeps the digest the hasher makes, not the password' do
    hasher = mock('hasher')
    hasher.expects(:digest).with('correct horse').returns('digest-of-it')

    user = User.register(id: 'u1', email: 'ada@example.com', password: 'correct horse', hasher: hasher)

    assert_equal 'digest-of-it', user.password_digest
  end

  test '.register normalises the email' do
    hasher = stub('hasher', digest: 'digest')

    user = User.register(id: 'u1', email: ' Ada@Example.com ', password: 'correct horse', hasher: hasher)

    assert_equal 'ada@example.com', user.email
  end

  test '.register when the password is short raises Invalid without hashing it' do
    hasher = mock('hasher')
    hasher.expects(:digest).never

    assert_raises(User::Invalid) do
      User.register(id: 'u1', email: 'ada@example.com', password: 'short', hasher: hasher)
    end
  end

  test '.register when the email is malformed raises Invalid without hashing the password' do
    hasher = mock('hasher')
    hasher.expects(:digest).never

    assert_raises(User::Invalid) { User.register(id: 'u1', email: 'ada', password: 'correct horse', hasher: hasher) }
  end

  test '.new without an id raises ArgumentError' do
    assert_raises(ArgumentError) { User.new(id: nil, email: 'ada@example.com', password_digest: 'd') }
  end

  test '.new without a password digest raises ArgumentError' do
    assert_raises(ArgumentError) { User.new(id: 'u1', email: 'ada@example.com', password_digest: '') }
  end

  test '#authenticate when the password matches the digest returns the user' do
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')
    hasher = stub('hasher')
    hasher.stubs(:matches?).with('correct horse', 'digest').returns(true)

    assert_same user, user.authenticate('correct horse', hasher)
  end

  test '#authenticate when the password does not match raises SignInFailed' do
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')
    hasher = stub('hasher', matches?: false)

    error = assert_raises(User::SignInFailed) { user.authenticate('wrong horse', hasher) }

    assert_equal 'Email or password is incorrect', error.message
  end

  test '#authenticate when the password is nil asks about an empty one' do
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')
    hasher = mock('hasher')
    hasher.expects(:matches?).with('', 'digest').returns(false)

    assert_raises(User::SignInFailed) { user.authenticate(nil, hasher) }
  end

  test 'NOBODY#authenticate fails as a wrong password does, without asking the hasher' do
    hasher = mock('hasher')
    hasher.expects(:matches?).never

    error = assert_raises(User::SignInFailed) { User::NOBODY.authenticate('correct horse', hasher) }

    assert_equal 'Email or password is incorrect', error.message
  end

  test '#== when the id, email and digest are the same is true' do
    assert_equal User.new(id: 'u1', email: 'ada@example.com', password_digest: 'd'),
                 User.new(id: 'u1', email: 'Ada@example.com', password_digest: 'd')
  end
end
