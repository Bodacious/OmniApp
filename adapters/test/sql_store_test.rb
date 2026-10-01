# frozen_string_literal: true

require 'test_helper'
require 'support/todo_repository_contract'
require 'support/list_repository_contract'
require 'support/user_repository_contract'
require 'support/password_hasher_contract'
require 'adapters/persistence/sql'
require 'adapters/passwords/scrypt_password_hasher'

##
# The port contracts, run against the Ruby adapters on every value of
# the persistence axis they serve.
module SqlStoreContracts
  include TodoRepositoryContract
  include ListRepositoryContract
  include UserRepositoryContract

  def repository
    store.todos
  end

  def list_repository
    store.lists
  end

  def user_repository
    store.users
  end
end

class SqliteMemoryStoreTest < Minitest::Test
  include SqlStoreContracts

  def store
    @store ||= Adapters::Persistence::Sql.store('sqlite_memory', {})
  end

  def test_it_reports_itself_as_sqlite_memory
    assert_equal 'sqlite_memory', store.persistence_name
  end
end

# Postgres needs a server. CI always provides DATABASE_URL; locally,
# `docker compose up -d` and export the URL it prints in the README.
if ENV['DATABASE_URL'].to_s.empty?
  raise 'DATABASE_URL is required in CI to run the postgres contract tests' if ENV['CI']

  warn 'DATABASE_URL is not set: not running the postgres repository contract tests'
else
  class PostgresStoreTest < Minitest::Test
    include SqlStoreContracts

    def setup
      store.clear
    end

    def teardown
      store.clear
    end

    def store
      @store ||= Adapters::Persistence::Sql.store('postgres', ENV)
    end

    def test_it_reports_itself_as_postgres
      assert_equal 'postgres', store.persistence_name
    end
  end
end

class ScryptPasswordHasherTest < Minitest::Test
  include PasswordHasherContract

  def password_hasher
    @password_hasher ||= Adapters::Passwords::ScryptPasswordHasher.new
  end

  def test_digests_use_the_shared_scrypt_format
    assert_match(/\Ascrypt\$16384\$8\$1\$[A-Za-z0-9+\/=]+\$[A-Za-z0-9+\/=]+\z/, password_hasher.digest('x' * 8))
  end
end
