# frozen_string_literal: true

# backtick_javascript: true

require 'todo'
require 'ports/todo_repository'
require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The repository port over Postgres through pg-native, which binds
    # libpq's synchronous API (connectSync, querySync), so the port
    # stays synchronous under Node. It uses the same table as the Ruby
    # adapter, so a Ruby stack and this one can share a database.
    class PostgresTodoRepository
      include Ports::TodoRepository

      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS todos (
          position SERIAL PRIMARY KEY,
          id TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          completed BOOLEAN NOT NULL DEFAULT FALSE
        )
      SQL

      def initialize(url)
        client_class = Node.require_module('pg-native')
        @client = `new #{client_class}()`
        `#{@client}.connectSync(#{url})`
        query(SCHEMA)
      end

      def persistence_name
        'postgres'
      end

      def all
        query('SELECT id, title, completed FROM todos ORDER BY position').map { |row| build(row) }
      end

      def find(id)
        row = query('SELECT id, title, completed FROM todos WHERE id = $1', [id.to_s]).first
        row && build(row)
      end

      def save(todo)
        query(<<~SQL, [todo.id, todo.title, todo.completed?])
          INSERT INTO todos (id, title, completed) VALUES ($1, $2, $3)
          ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, completed = EXCLUDED.completed
        SQL
        todo
      end

      def delete(id)
        query('DELETE FROM todos WHERE id = $1 RETURNING id', [id.to_s]).any?
      end

      # Not part of the port: the composition root's test-only reset.
      def clear
        query('DELETE FROM todos')
        nil
      end

      private

      # Rows come back as a JS array of plain objects.
      def query(sql, params = [])
        `#{@client}.querySync(#{sql}, #{params})`
      end

      def build(row)
        Todo.new(id: `#{row}.id`, title: `#{row}.title`, completed: `#{row}.completed` == true)
      end
    end
  end
end
