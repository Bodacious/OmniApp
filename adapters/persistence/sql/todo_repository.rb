# frozen_string_literal: true

require 'sequel'
require_relative '../../../domain/todo'
require_relative '../../../domain/ports/todo_repository'

module Adapters
  module Persistence
    module Sql
      ##
      # The repository port over a Sequel database. The same class
      # serves both the sqlite_memory and postgres stacks: only the
      # connection handed to it differs (see Sql.connect).
      class TodoRepository
        include Ports::TodoRepository

        TABLE = :todos

        ##
        # Creates the table if it isn't there yet, so booting against an
        # existing database is harmless. +position+ exists only to keep
        # todos in the order they were added; a todo's identity is its
        # +id+, which the domain generates.
        def self.create_schema(database)
          database.create_table?(TABLE) do
            primary_key :position
            String :id, null: false, unique: true
            String :title, null: false, text: true
            TrueClass :completed, null: false, default: false
          end
        end

        def initialize(database)
          @database = database
          self.class.create_schema(database)
        end

        def all
          todos.order(:position).map { |row| build(row) }
        end

        def find(id)
          row = todos.where(id: id.to_s).first
          row && build(row)
        end

        def save(todo)
          todos.insert_conflict(target: :id,
                                update: { title: ::Sequel[:excluded][:title],
                                          completed: ::Sequel[:excluded][:completed] })
               .insert(id: todo.id, title: todo.title, completed: todo.completed?)
          todo
        end

        def delete(id)
          todos.where(id: id.to_s).delete.positive?
        end

        # Not part of the port: the composition root's test-only reset.
        def clear
          todos.delete
          nil
        end

        # Which persistence this really is, read from the live
        # connection rather than from configuration, for /health.
        def persistence_name
          case database.database_type
          when :sqlite then in_memory? ? 'sqlite_memory' : 'sqlite_file'
          when :postgres then 'postgres'
          else database.database_type.to_s
          end
        end

        private

        attr_reader :database

        def todos
          database[TABLE]
        end

        def in_memory?
          ['', ':memory:'].include?(database.opts[:database].to_s)
        end

        def build(row)
          Todo.new(id: row[:id], title: row[:title], completed: row[:completed])
        end
      end
    end
  end
end
