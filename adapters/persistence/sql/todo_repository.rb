# frozen_string_literal: true

require 'sequel'
require_relative '../../../domain/model/todo'
require_relative '../../../domain/ports/todo_repository'

module Adapters
  module Persistence
    module Sql
      ##
      # The repository port over a Sequel database. The same class
      # serves both the sqlite_memory and postgres stacks: only the
      # connection handed to it differs (see Sql.connect).
      #
      # A Todo's tags live in their own table, one row per tag, so the
      # schema is relational even though the domain just sees Todo#tags.
      class TodoRepository
        include Ports::TodoRepository

        TODOS = :todos
        TAGS = :todo_tags

        ##
        # Creates the tables if they aren't there yet, so booting against
        # an existing database is harmless, including one from before
        # todos had tags. +position+ exists only to keep todos in the
        # order they were added; a todo's identity is its +id+, which the
        # domain generates.
        def self.create_schema(database)
          database.create_table?(TODOS) do
            primary_key :position
            String :id, null: false, unique: true
            String :title, null: false, text: true
            TrueClass :completed, null: false, default: false
          end
          database.create_table?(TAGS) do
            String :todo_id, null: false
            String :tag, null: false
            primary_key %i[todo_id tag]
          end
        end

        def initialize(database)
          @database = database
          self.class.create_schema(database)
        end

        def all
          rows = todos.order(:position).all
          tags = tags_by_todo(rows.map { |row| row[:id] })
          rows.map { |row| build(row, tags.fetch(row[:id], [])) }
        end

        def find(id)
          row = todos.where(id: id.to_s).first
          row && build(row, tags_by_todo([row[:id]]).fetch(row[:id], []))
        end

        def save(todo)
          database.transaction do
            todos.insert_conflict(target: :id,
                                  update: { title: ::Sequel[:excluded][:title],
                                            completed: ::Sequel[:excluded][:completed] })
                 .insert(id: todo.id, title: todo.title, completed: todo.completed?)
            tags.where(todo_id: todo.id).delete
            tags.multi_insert(todo.tags.map { |tag| { todo_id: todo.id, tag: tag.name } })
          end
          todo
        end

        def delete(id)
          database.transaction do
            tags.where(todo_id: id.to_s).delete
            todos.where(id: id.to_s).delete.positive?
          end
        end

        # Not part of the port: the composition root's test-only reset.
        def clear
          database.transaction do
            tags.delete
            todos.delete
          end
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
          database[TODOS]
        end

        def tags
          database[TAGS]
        end

        def tags_by_todo(ids)
          return {} if ids.empty?

          tags.where(todo_id: ids).select_map(%i[todo_id tag])
              .group_by(&:first)
              .transform_values { |pairs| pairs.map(&:last) }
        end

        def in_memory?
          ['', ':memory:'].include?(database.opts[:database].to_s)
        end

        def build(row, tag_names)
          Todo.new(id: row[:id], title: row[:title], completed: row[:completed], tags: tag_names)
        end
      end
    end
  end
end
