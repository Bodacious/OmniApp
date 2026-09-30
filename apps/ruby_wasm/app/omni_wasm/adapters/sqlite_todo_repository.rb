# frozen_string_literal: true

require 'js'
require_relative '../../../../../domain/model/todo'
require_relative '../../../../../domain/ports/todo_repository'

module OmniWasm
  module Adapters
    ##
    # The repository port over SQLite, which is itself compiled to
    # WebAssembly and runs alongside CRuby. boot.js hands Ruby a small
    # synchronous facade over SQLite's oo1 API; this adapter drives it
    # through the js gem. It's synchronous end to end, like the port.
    #
    # One class serves every SQLite-backed persistence: only the
    # database handed in differs (in memory, or kept in localStorage).
    #
    # Tags live in their own table, one row per tag, as in the server
    # adapters; saving a todo rewrites its tags in the same transaction.
    class SqliteTodoRepository
      include Ports::TodoRepository

      SCHEMA = [<<~SQL, <<~SQL].freeze
        CREATE TABLE IF NOT EXISTS todos (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
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

      UPSERT = <<~SQL
        INSERT INTO todos (id, title, completed) VALUES (?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
      SQL

      attr_reader :persistence_name

      def initialize(database, persistence_name, tracer: nil)
        @database = database
        @persistence_name = persistence_name
        @tracer = tracer
        SCHEMA.each { |statement| query(statement) }
      end

      def all
        tags = tags_by_todo(query('SELECT todo_id, tag FROM todo_tags'))
        query('SELECT id, title, completed FROM todos ORDER BY position').map do |row|
          build(row, tags.fetch(row[:id].to_s, []))
        end
      end

      def find(id)
        row = query('SELECT id, title, completed FROM todos WHERE id = ?', id.to_s).first
        return nil unless row

        build(row, tags_by_todo(query('SELECT todo_id, tag FROM todo_tags WHERE todo_id = ?', id.to_s))
                     .fetch(id.to_s, []))
      end

      def save(todo)
        transaction do
          query(UPSERT, todo.id, todo.title, todo.completed? ? 1 : 0)
          query('DELETE FROM todo_tags WHERE todo_id = ?', todo.id)
          todo.tags.each { |tag| query('INSERT INTO todo_tags (todo_id, tag) VALUES (?, ?)', todo.id, tag.name) }
        end
        todo
      end

      def delete(id)
        transaction do
          query('DELETE FROM todo_tags WHERE todo_id = ?', id.to_s)
          query('DELETE FROM todos WHERE id = ?', id.to_s)
          @database.call(:changes).to_i.positive?
        end
      end

      # Not part of the port: lets the contract runner start clean.
      def clear
        transaction do
          query('DELETE FROM todo_tags')
          query('DELETE FROM todos')
        end
        nil
      end

      private

      # Rows come back as a JS array of plain objects.
      def query(sql, *bind)
        @tracer&.note(:adapter, "SQL #{sql.split.join(' ')}")
        rows = @database.call(:query, sql, *bind)
        Array.new(rows[:length].to_i) { |index| rows[index] }
      end

      def transaction
        query('BEGIN')
        result = yield
        query('COMMIT')
        result
      rescue StandardError
        query('ROLLBACK')
        raise
      end

      # { todo id => [tag names] }
      def tags_by_todo(rows)
        rows.each_with_object({}) { |row, tags| (tags[row[:todo_id].to_s] ||= []) << row[:tag].to_s }
      end

      def build(row, tag_names)
        Todo.new(id: row[:id].to_s, title: row[:title].to_s, completed: row[:completed].to_i == 1, tags: tag_names)
      end
    end
  end
end
