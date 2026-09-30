# frozen_string_literal: true

require 'sequel'
require_relative 'sql/todo_repository'

module Adapters
  module Persistence
    ##
    # The Ruby persistence adapters, shared by the Rails and Sinatra
    # apps. Each entry opens a Sequel connection for one value of the
    # persistence axis in config/stack_matrix.yml.
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

      def self.names
        CONNECTIONS.keys
      end

      # A Ports::TodoRepository for the named persistence, schema ready.
      def self.todo_repository(name, env)
        connect = CONNECTIONS.fetch(name) do
          raise ConfigurationError, "No Ruby persistence adapter named #{name.inspect}. Known: #{names.join(', ')}"
        end
        TodoRepository.new(connect.call(env))
      end
    end
  end
end
