# frozen_string_literal: true

require 'sequel'
require_relative 'sql/schema'
require_relative 'sql/user_repository'
require_relative 'sql/list_repository'
require_relative 'sql/todo_repository'

module Adapters
  module Persistence
    ##
    # The Ruby persistence adapters, shared by the Rails and Sinatra
    # apps: one Sequel connection per value of the persistence axis in
    # config/stack_matrix.yml, and a repository for each of the domain's
    # storage ports on top of it.
    module Sql
      class ConfigurationError < StandardError; end

      CONNECTIONS = {
        # Every SQLite connection to :memory: gets its own, separate
        # database. A pool of exactly one connection means every request,
        # on every thread, sees the same data.
        'sqlite_memory' => ->(_env) { ::Sequel.sqlite(max_connections: 1) },

        'postgres' => lambda do |env|
          url = env['DATABASE_URL'].to_s
          if url.empty?
            raise ConfigurationError,
                  'OMNI_PERSISTENCE=postgres needs DATABASE_URL, e.g. ' \
                  'postgres://postgres:postgres@localhost:5432/omni (see docker-compose.yml)'
          end
          ::Sequel.connect(url)
        end
      }.freeze

      ##
      # The repositories for one database, plus the two things the
      # composition root needs that aren't part of any port: which
      # database this really is (for /health) and a way to empty it
      # (for the test-only reset).
      class Store
        attr_reader :users, :lists, :todos

        def initialize(database)
          @database = database
          Schema.create(database)
          @users = UserRepository.new(database)
          @lists = ListRepository.new(database)
          @todos = TodoRepository.new(database)
        end

        # Read from the live connection rather than from configuration.
        def persistence_name
          case @database.database_type
          when :sqlite then ['', ':memory:'].include?(@database.opts[:database].to_s) ? 'sqlite_memory' : 'sqlite_file'
          when :postgres then 'postgres'
          else @database.database_type.to_s
          end
        end

        def clear
          @database.transaction do
            todos.clear
            lists.clear
            users.clear
          end
        end
      end

      def self.names
        CONNECTIONS.keys
      end

      # A Store for the named persistence, schema ready.
      def self.store(name, env)
        connect = CONNECTIONS.fetch(name) do
          raise ConfigurationError, "No Ruby persistence adapter named #{name.inspect}. Known: #{names.join(', ')}"
        end
        Store.new(connect.call(env))
      end
    end
  end
end
