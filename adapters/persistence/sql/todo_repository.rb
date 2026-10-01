# frozen_string_literal: true

require 'sequel'
require_relative '../../../domain/model/todo'
require_relative '../../../domain/ports/todo_repository'

module Adapters
  module Persistence
    module Sql
      ##
      # The todo repository port over a Sequel database. Like the user
      # and list repositories, the same class serves both the
      # sqlite_memory and postgres stacks: only the connection handed to
      # it differs (see Sql.store), and Schema creates the tables.
      #
      # A Todo's tags live in their own table, one row per tag, so the
      # schema is relational even though the domain just sees Todo#tags.
      class TodoRepository
        include Ports::TodoRepository

        TODOS = :todos
        TAGS = :todo_tags

        def initialize(database)
          @database = database
        end

        def in_list(list_id)
          rows = todos.where(list_id: list_id.to_s).order(:position).all
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
                 .insert(id: todo.id, list_id: todo.list_id, title: todo.title, completed: todo.completed?)
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

        def build(row, tag_names)
          Todo.new(id: row[:id], list_id: row[:list_id], title: row[:title], completed: row[:completed],
                   tags: tag_names)
        end
      end
    end
  end
end
