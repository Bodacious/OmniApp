# frozen_string_literal: true

require 'model/user_repository'

##
# The behaviour every UserRepository implementation must provide (see
# domain/model/user_repository.rb). Include it into a Minitest::Test
# that defines +user_repository+, returning the implementation under
# test backed by an empty store.
module UserRepositoryContract
  def test_user_repository_is_a_user_repository
    assert_kind_of UserRepository, user_repository
  end

  def test_next_identity_is_a_new_string_every_time
    ids = Array.new(3) { user_repository.next_identity }

    assert_equal 3, ids.uniq.size
    assert_kind_of String, ids.first
  end

  def test_save_returns_the_user
    user = User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest')

    assert_same user, user_repository.save(user)
  end

  def test_find_returns_a_saved_user
    user_repository.save(User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest'))

    assert_equal User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest'), user_repository.find('u1')
  end

  def test_find_by_email_returns_a_saved_user
    user_repository.save(User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest'))

    assert_equal 'u1', user_repository.find_by_email('ada@example.com').id
  end

  def test_unknown_users_are_nil
    assert_equal [nil, nil, nil], [user_repository.find('missing'), user_repository.find(nil),
                                   user_repository.find_by_email('nobody@example.com')]
  end

  def test_save_replaces_a_user_with_the_same_id
    user_repository.save(User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest-1'))

    user_repository.save(User.new(id: 'u1', email: 'ada@example.com', password_digest: 'digest-2'))

    assert_equal 'digest-2', user_repository.find('u1').password_digest
  end
end
