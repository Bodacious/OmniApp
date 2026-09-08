# frozen_string_literal: true

require 'logger'
require 'sequel'
require 'sqlite3'

module Persistence
  module Sql
    ##
    # Opens a SQLite connection and puts the schema in place. Both are
    # explicit calls made by an app's composition root rather than
    # side effects of requiring this file, so loading code never
    # connects to a database on its own.
    #
    # The environment is passed in rather than sniffed from ENV here:
    # Sinatra knows it as RACK_ENV and Rails as RAILS_ENV, and which
    # one applies is the app's business, not the persistence layer's.
    module Database
      ROOT = File.expand_path('../..', __dir__)

      def self.connect(environment)
        ::Sequel.sqlite(database: database_path(environment),
                        logger: Logger.new(log_path(environment)))
      end

      ##
      # Creates any missing tables. Pass reset: true (as the test
      # environment does) to drop them first, so each run starts from
      # a known-empty schema.
      def self.create_schema!(database, reset: false)
        drop_schema!(database) if reset

        database.create_table?(:lists) do
          primary_key :id
          String :name, null: false
          String :slug, unique: true, null: false
        end

        database.create_table?(:list_items) do
          primary_key :id
          String :summary, null: false
          foreign_key :list_id, references: :lists, null: false
        end
      end

      def self.drop_schema!(database)
        database.drop_table?(:list_items)
        database.drop_table?(:lists)
      end

      def self.database_path(environment)
        File.join(ROOT, 'databases', "#{environment}.db")
      end

      def self.log_path(environment)
        File.join(ROOT, 'log', "#{environment}.db.log")
      end
    end
  end
end
