# frozen_string_literal: true

require 'js'
require_relative '../../../../../domain/todo'
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
    class SqliteTodoRepository
      include Ports::TodoRepository

      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS todos (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0
        )
      SQL

      attr_reader :persistence_name

      def initialize(database, persistence_name, tracer: nil)
        @database = database
        @persistence_name = persistence_name
        @tracer = tracer
        query(SCHEMA)
      end

      def all
        query('SELECT id, title, completed FROM todos ORDER BY position').map { |row| build(row) }
      end

      def find(id)
        row = query('SELECT id, title, completed FROM todos WHERE id = ?', id.to_s).first
        row && build(row)
      end

      def save(todo)
        query(<<~SQL, todo.id, todo.title, todo.completed? ? 1 : 0)
          INSERT INTO todos (id, title, completed) VALUES (?, ?, ?)
          ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
        SQL
        todo
      end

      def delete(id)
        query('DELETE FROM todos WHERE id = ?', id.to_s)
        @database.call(:changes).to_i.positive?
      end

      # Not part of the port: lets the contract runner start clean.
      def clear
        query('DELETE FROM todos')
        nil
      end

      private

      # Rows come back as a JS array of plain objects.
      def query(sql, *bind)
        @tracer&.note(:adapter, "SQL #{sql.split.join(' ')}")
        rows = @database.call(:query, sql, *bind)
        Array.new(rows[:length].to_i) { |index| rows[index] }
      end

      def build(row)
        Todo.new(id: row[:id].to_s, title: row[:title].to_s, completed: row[:completed].to_i == 1)
      end
    end
  end
end
