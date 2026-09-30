# frozen_string_literal: true

# backtick_javascript: true

require 'todo'
require 'ports/todo_repository'
require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The repository port over Node's built-in SQLite (node:sqlite),
    # whose DatabaseSync API is synchronous, like the port.
    #
    # One DatabaseSync on ':memory:' is one private in-memory database.
    # Node runs requests on a single thread, so this one connection
    # serves them all and every request sees the same data.
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

      def initialize(path = ':memory:')
        @path = path
        database_sync = `#{Node.require_module('node:sqlite')}.DatabaseSync`
        @database = `new #{database_sync}(#{path})`
        `#{@database}.exec(#{SCHEMA})`
      end

      def persistence_name
        @path == ':memory:' ? 'sqlite_memory' : 'sqlite_file'
      end

      def all
        rows = `#{prepare('SELECT id, title, completed FROM todos ORDER BY position')}.all()`
        rows.map { |row| build(row) }
      end

      def find(id)
        row = Node.to_ruby(`#{prepare('SELECT id, title, completed FROM todos WHERE id = ?')}.get(#{id.to_s})`)
        row && build(row)
      end

      def save(todo)
        statement = prepare(<<~SQL)
          INSERT INTO todos (id, title, completed) VALUES (?, ?, ?)
          ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
        SQL
        `#{statement}.run(#{todo.id}, #{todo.title}, #{todo.completed? ? 1 : 0})`
        todo
      end

      def delete(id)
        result = `#{prepare('DELETE FROM todos WHERE id = ?')}.run(#{id.to_s})`
        `Number(#{result}.changes)` > 0
      end

      # Not part of the port: the composition root's test-only reset.
      def clear
        `#{@database}.exec('DELETE FROM todos')`
        nil
      end

      private

      def prepare(sql)
        `#{@database}.prepare(#{sql})`
      end

      def build(row)
        Todo.new(id: `#{row}.id`, title: `#{row}.title`, completed: `#{row}.completed` == 1)
      end
    end
  end
end
