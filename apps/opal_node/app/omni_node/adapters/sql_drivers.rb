# frozen_string_literal: true

# backtick_javascript: true

require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The two synchronous SQL drivers the Node app's repositories run
    # on. Repositories write SQL once, with ? placeholders; a driver
    # deals with its database's differences: placeholder style, how
    # booleans are stored, and the DDL.
    #
    # [query(sql, params)]   rows, as a JS array of plain objects
    # [execute(sql, params)] runs a statement that returns no rows
    # [transaction { }]      BEGIN ... COMMIT, or ROLLBACK on an error
    # [boolean(value)]       a Ruby boolean as this database stores it
    # [true?(value)]         a stored boolean read back
    module SqlDriver
      def transaction
        execute('BEGIN')
        result = yield
        execute('COMMIT')
        result
      rescue Exception # rubocop:disable Lint/RescueException -- JS errors from the driver too
        execute('ROLLBACK')
        raise
      end
    end

    ##
    # Node's built-in SQLite (node:sqlite), whose DatabaseSync API is
    # synchronous. One DatabaseSync on ':memory:' is one private
    # database; Node serves every request on one thread, so this one
    # connection sees everything.
    class SqliteDriver
      include SqlDriver

      SCHEMA = [<<~SQL, <<~SQL, <<~SQL, <<~SQL].freeze
        CREATE TABLE IF NOT EXISTS users (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password_digest TEXT NOT NULL
        )
      SQL
        CREATE TABLE IF NOT EXISTS lists (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          owner_id TEXT NOT NULL,
          name TEXT NOT NULL
        )
      SQL
        CREATE TABLE IF NOT EXISTS todos (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          list_id TEXT,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0
        )
      SQL
        CREATE TABLE IF NOT EXISTS todo_tags (
          todo_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (todo_id, tag)
        )
      SQL

      def initialize(path = ':memory:')
        @path = path
        database_sync = `#{Node.require_module('node:sqlite')}.DatabaseSync`
        @database = `new #{database_sync}(#{path})`
        SCHEMA.each { |statement| execute(statement) }
      end

      def persistence_name
        @path == ':memory:' ? 'sqlite_memory' : 'sqlite_file'
      end

      def query(sql, params = [])
        `#{@database}.prepare(#{sql}).all(...#{params})`
      end

      def execute(sql, params = [])
        `#{@database}.prepare(#{sql}).run(...#{params})`
        nil
      end

      def boolean(value)
        value ? 1 : 0
      end

      def true?(value)
        value == 1
      end
    end

    ##
    # Postgres through pg-native, which binds libpq's synchronous API
    # (connectSync, querySync), so the ports stay synchronous under Node.
    # Its tables match the Ruby adapters', so a Ruby stack and this one
    # can share a database.
    class PostgresDriver
      include SqlDriver

      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS users (
          position SERIAL PRIMARY KEY,
          id TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password_digest TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS lists (
          position SERIAL PRIMARY KEY,
          id TEXT NOT NULL UNIQUE,
          owner_id TEXT NOT NULL,
          name TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS todos (
          position SERIAL PRIMARY KEY,
          id TEXT NOT NULL UNIQUE,
          list_id TEXT,
          title TEXT NOT NULL,
          completed BOOLEAN NOT NULL DEFAULT FALSE
        );
        ALTER TABLE todos ADD COLUMN IF NOT EXISTS list_id TEXT;
        CREATE TABLE IF NOT EXISTS todo_tags (
          todo_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (todo_id, tag)
        );
      SQL

      def initialize(url)
        client_class = Node.require_module('pg-native')
        @client = `new #{client_class}()`
        `#{@client}.connectSync(#{url})`
        # Keep "relation already exists, skipping" notices out of the log.
        execute('SET client_min_messages TO WARNING')
        execute(SCHEMA)
      end

      def persistence_name
        'postgres'
      end

      # Without params, pg-native uses libpq's simple protocol, which
      # (unlike the extended one) runs several statements at once, as
      # SCHEMA needs.
      def query(sql, params = [])
        index = 0
        numbered = sql.gsub('?') { index += 1; "$#{index}" } # rubocop:disable Style/Semicolon
        params.empty? ? `#{@client}.querySync(#{numbered})` : `#{@client}.querySync(#{numbered}, #{params})`
      end

      def execute(sql, params = [])
        query(sql, params)
        nil
      end

      def boolean(value)
        value ? true : false
      end

      def true?(value)
        value == true
      end
    end
  end
end
