# frozen_string_literal: true

require 'model/user'

##
# The behaviour every Ports::UserRepository adapter must provide (see
# domain/ports/user_repository.rb). Include it into a Minitest::Test
# that defines +user_repository+, returning the adapter under test
# backed by an empty store.
module UserRepositoryContract
  def test_user_repository_implements_the_port
    assert_kind_of Ports::UserRepository, user_repository
  end

  def test_find_and_find_by_email_return_a_saved_user
    user = user_repository.save(user('u1', 'ada@example.com'))

    assert_equal user, user_repository.find('u1')
    assert_equal user, user_repository.find_by_email('ada@example.com')
  end

  def test_unknown_users_are_nil
    assert_nil user_repository.find('missing')
    assert_nil user_repository.find_by_email('nobody@example.com')
  end

  def test_save_replaces_a_user_with_the_same_id
    user_repository.save(user('u1', 'ada@example.com', 'digest-1'))

    user_repository.save(user('u1', 'ada@example.com', 'digest-2'))

    assert_equal 'digest-2', user_repository.find('u1').password_digest
  end

  private

  def user(id, email, digest = 'digest')
    User.new(id: id, email: email, password_digest: digest)
  end
end
