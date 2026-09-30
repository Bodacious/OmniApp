# frozen_string_literal: true

require 'test_helper'
require 'support/todo_repository_contract'
require 'adapters/persistence/sql'

##
# The repository contract, run against the Ruby persistence adapter on
# every value of the persistence axis it serves.
class SqliteMemoryTodoRepositoryTest < Minitest::Test
  include TodoRepositoryContract

  def repository
    @repository ||= Adapters::Persistence::Sql.todo_repository('sqlite_memory', {})
  end

  def test_it_reports_itself_as_sqlite_memory
    assert_equal 'sqlite_memory', repository.persistence_name
  end
end

# Postgres needs a server. CI always provides DATABASE_URL; locally,
# `docker compose up -d` and export the URL it prints in the README.
if ENV['DATABASE_URL'].to_s.empty?
  raise 'DATABASE_URL is required in CI to run the postgres contract tests' if ENV['CI']

  warn 'DATABASE_URL is not set: not running the postgres repository contract tests'
else
  class PostgresTodoRepositoryTest < Minitest::Test
    include TodoRepositoryContract

    def setup
      repository.clear
    end

    def teardown
      repository.clear
    end

    def repository
      @repository ||= Adapters::Persistence::Sql.todo_repository('postgres', ENV)
    end

    def test_it_reports_itself_as_postgres
      assert_equal 'postgres', repository.persistence_name
    end
  end
end
