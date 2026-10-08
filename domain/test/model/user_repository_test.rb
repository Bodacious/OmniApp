# frozen_string_literal: true

require 'test_helper'
require 'model/user_repository'

class UserRepositoryTest < ActiveSupport::TestCase
  test '#add when the email has no account saves the user and returns it' do
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')
    repository = Class.new { include UserRepository }.new
    repository.stubs(:find_by_email).with('ada@example.com').returns(nil)
    repository.expects(:save).with(user).returns(user)

    assert_same user, repository.add(user)
  end

  test '#add when the email already has an account raises Invalid without saving' do
    user = User.new(id: 'u2', email: 'ada@example.com', password_digest: 'digest')
    repository = Class.new { include UserRepository }.new
    repository.stubs(:find_by_email).with('ada@example.com').returns(user)
    repository.expects(:save).never

    error = assert_raises(User::Invalid) { repository.add(user) }

    assert_equal 'That email already has an account', error.message
  end

  test '#account_for when the email has an account returns its user' do
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')
    repository = Class.new { include UserRepository }.new
    repository.stubs(:find_by_email).with('ada@example.com').returns(user)

    assert_same user, repository.account_for(' Ada@Example.com ')
  end

  test '#account_for when the email has no account returns NOBODY' do
    repository = Class.new { include UserRepository }.new
    repository.stubs(:find_by_email).returns(nil)

    assert_same User::NOBODY, repository.account_for('bob@example.com')
  end

  test '#account_for when the email is malformed returns NOBODY without looking' do
    repository = Class.new { include UserRepository }.new
    repository.expects(:find_by_email).never

    assert_same User::NOBODY, repository.account_for('not an email')
  end

  test 'the storage methods when not implemented raise NotImplementedError' do
    repository = Class.new { include UserRepository }.new

    [-> { repository.next_identity }, -> { repository.find('u1') }, -> { repository.find_by_email('a@b.c') },
     -> { repository.save(nil) }].each { |call| assert_raises(NotImplementedError, &call) }
  end
end
