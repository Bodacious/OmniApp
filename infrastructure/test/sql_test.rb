# frozen_string_literal: true

require 'test_helper'
require 'support/list_repository_contract'
require 'support/user_repository_contract'
require 'support/password_hasher_contract'
require 'infrastructure/sql'
require 'infrastructure/scrypt_password_hasher'

##
# The repository contracts, run against the Sequel repositories on
# every value of the persistence axis they serve.
module SqlStoreContracts
  include ListRepositoryContract
  include UserRepositoryContract

  def list_repository
    store.lists
  end

  def user_repository
    store.users
  end
end

class SqliteMemoryStoreTest < ActiveSupport::TestCase
  include SqlStoreContracts

  def store
    @store ||= Infrastructure::Sql.store('sqlite_memory', {})
  end

  test '#persistence_name on an in-memory SQLite database is sqlite_memory' do
    assert_equal 'sqlite_memory', store.persistence_name
  end
end

# Postgres needs a server. CI always provides DATABASE_URL; locally,
# `docker compose up -d` and export the URL it prints in the README.
if ENV['DATABASE_URL'].to_s.empty?
  raise 'DATABASE_URL is required in CI to run the postgres contract tests' if ENV['CI']

  warn 'DATABASE_URL is not set: not running the postgres repository contract tests'
else
  class PostgresStoreTest < ActiveSupport::TestCase
    include SqlStoreContracts

    setup { store.clear }
    teardown { store.clear }

    def store
      @store ||= Infrastructure::Sql.store('postgres', ENV)
    end

    test '#persistence_name on Postgres is postgres' do
      assert_equal 'postgres', store.persistence_name
    end
  end
end

class ScryptPasswordHasherTest < ActiveSupport::TestCase
  include PasswordHasherContract

  def password_hasher
    @password_hasher ||= Infrastructure::ScryptPasswordHasher.new
  end

  test '#digest uses the scrypt format the Node hasher shares' do
    assert_match(%r{\Ascrypt\$16384\$8\$1\$[A-Za-z0-9+/=]+\$[A-Za-z0-9+/=]+\z}, password_hasher.digest('x' * 8))
  end
end
