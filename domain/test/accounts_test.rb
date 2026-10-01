# frozen_string_literal: true

require 'test_helper'
require 'accounts'
require 'support/in_memory_user_repository'
require 'support/fake_password_hasher'
require 'support/sequential_id_generator'

class AccountsTest < Minitest::Test
  def setup
    @users = InMemoryUserRepository.new
    @ids = SequentialIdGenerator.new
    @accounts = Accounts.new(users: @users, password_hasher: FakePasswordHasher.new, id_generator: @ids)
  end

  def test_sign_up_stores_a_user_with_a_digest_not_the_password
    user = @accounts.sign_up(email: ' Ada@Example.com ', password: 'correct horse')

    assert_equal 'ada@example.com', user.email
    assert_equal user, @users.find(user.id)
    refute_includes user.password_digest, 'correct horse'
  end

  def test_sign_up_rejects_bad_input_without_storing_anything_or_spending_an_id
    assert_raises(User::Invalid) { @accounts.sign_up(email: 'not an email', password: 'correct horse') }
    assert_raises(User::Invalid) { @accounts.sign_up(email: 'ada@example.com', password: 'short') }
    assert_nil @users.find_by_email('ada@example.com')
    assert_equal 'todo-1', @ids.next_id
  end

  def test_an_email_can_only_have_one_account
    @accounts.sign_up(email: 'ada@example.com', password: 'correct horse')

    error = assert_raises(User::Invalid) { @accounts.sign_up(email: 'ADA@example.com', password: 'another one') }

    assert_equal 'That email already has an account', error.message
  end

  def test_sign_in_returns_the_user_for_the_right_credentials
    user = @accounts.sign_up(email: 'ada@example.com', password: 'correct horse')

    assert_equal user, @accounts.sign_in(email: 'Ada@example.com ', password: 'correct horse')
  end

  def test_sign_in_fails_the_same_way_for_a_wrong_password_an_unknown_or_a_malformed_email
    @accounts.sign_up(email: 'ada@example.com', password: 'correct horse')

    [%w[ada@example.com wrong-horse], %w[bob@example.com correct-horse], ['not an email', 'x']].each do |email, password|
      error = assert_raises(Accounts::SignInFailed) { @accounts.sign_in(email: email, password: password) }

      assert_equal 'Email or password is incorrect', error.message
    end
  end

  def test_find_restores_a_user_by_id
    user = @accounts.sign_up(email: 'ada@example.com', password: 'correct horse')

    assert_equal user, @accounts.find(user.id)
    assert_nil @accounts.find('missing')
    assert_nil @accounts.find(nil)
  end
end
