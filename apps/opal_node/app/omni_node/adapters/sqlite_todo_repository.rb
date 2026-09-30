# frozen_string_literal: true

# backtick_javascript: true

require 'model/todo'
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
    #
    # Tags live in their own table, one row per tag, as in the Ruby
    # adapter; saving a todo rewrites its tags in the same transaction.
    class SqliteTodoRepository
      include Ports::TodoRepository

      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS todos (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS todo_tags (
          todo_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (todo_id, tag)
        );
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
        tags = tags_by_todo(`#{prepare('SELECT todo_id, tag FROM todo_tags')}.all()`)
        rows = `#{prepare('SELECT id, title, completed FROM todos ORDER BY position')}.all()`
        rows.map { |row| build(row, tags.fetch(`#{row}.id`, [])) }
      end

      def find(id)
        row = Node.to_ruby(`#{prepare('SELECT id, title, completed FROM todos WHERE id = ?')}.get(#{id.to_s})`)
        return nil unless row

        tags = `#{prepare('SELECT todo_id, tag FROM todo_tags WHERE todo_id = ?')}.all(#{id.to_s})`
        build(row, tags_by_todo(tags).fetch(id.to_s, []))
      end

      def save(todo)
        transaction do
          `#{prepare(UPSERT)}.run(#{todo.id}, #{todo.title}, #{todo.completed? ? 1 : 0})`
          `#{prepare('DELETE FROM todo_tags WHERE todo_id = ?')}.run(#{todo.id})`
          insert = prepare('INSERT INTO todo_tags (todo_id, tag) VALUES (?, ?)')
          todo.tags.each { |tag| `#{insert}.run(#{todo.id}, #{tag.name})` }
        end
        todo
      end

      def delete(id)
        transaction do
          `#{prepare('DELETE FROM todo_tags WHERE todo_id = ?')}.run(#{id.to_s})`
          result = `#{prepare('DELETE FROM todos WHERE id = ?')}.run(#{id.to_s})`
          `Number(#{result}.changes)` > 0
        end
      end

      # Not part of the port: the composition root's test-only reset.
      def clear
        `#{@database}.exec('DELETE FROM todo_tags; DELETE FROM todos;')`
        nil
      end

      private

      UPSERT = <<~SQL
        INSERT INTO todos (id, title, completed) VALUES (?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
      SQL

      def transaction
        `#{@database}.exec('BEGIN')`
        result = yield
        `#{@database}.exec('COMMIT')`
        result
      rescue Exception # rubocop:disable Lint/RescueException -- JS errors from SQLite too
        `#{@database}.exec('ROLLBACK')`
        raise
      end

      def prepare(sql)
        `#{@database}.prepare(#{sql})`
      end

      # { todo id => [tag names] } from JS rows of todo_id and tag.
      def tags_by_todo(rows)
        rows.each_with_object({}) { |row, tags| (tags[`#{row}.todo_id`] ||= []) << `#{row}.tag` }
      end

      def build(row, tag_names)
        Todo.new(id: `#{row}.id`, title: `#{row}.title`, completed: `#{row}.completed` == 1, tags: tag_names)
      end
    end
  end
end
