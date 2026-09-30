# frozen_string_literal: true

# backtick_javascript: true

require 'model/todo'
require 'ports/todo_repository'
require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The repository port over Postgres through pg-native, which binds
    # libpq's synchronous API (connectSync, querySync), so the port
    # stays synchronous under Node. It uses the same tables as the Ruby
    # adapter, so a Ruby stack and this one can share a database.
    class PostgresTodoRepository
      include Ports::TodoRepository

      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS todos (
          position SERIAL PRIMARY KEY,
          id TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          completed BOOLEAN NOT NULL DEFAULT FALSE
        );
        CREATE TABLE IF NOT EXISTS todo_tags (
          todo_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (todo_id, tag)
        );
      SQL

      UPSERT = <<~SQL
        INSERT INTO todos (id, title, completed) VALUES ($1, $2, $3)
        ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, completed = EXCLUDED.completed
      SQL

      def initialize(url)
        client_class = Node.require_module('pg-native')
        @client = `new #{client_class}()`
        `#{@client}.connectSync(#{url})`
        # Keep "relation already exists, skipping" notices out of the log.
        query('SET client_min_messages TO WARNING')
        query(SCHEMA)
      end

      def persistence_name
        'postgres'
      end

      def all
        tags = tags_by_todo(query('SELECT todo_id, tag FROM todo_tags'))
        query('SELECT id, title, completed FROM todos ORDER BY position').map do |row|
          build(row, tags.fetch(`#{row}.id`, []))
        end
      end

      def find(id)
        row = query('SELECT id, title, completed FROM todos WHERE id = $1', [id.to_s]).first
        return nil unless row

        tags = tags_by_todo(query('SELECT todo_id, tag FROM todo_tags WHERE todo_id = $1', [id.to_s]))
        build(row, tags.fetch(id.to_s, []))
      end

      def save(todo)
        transaction do
          query(UPSERT, [todo.id, todo.title, todo.completed?])
          query('DELETE FROM todo_tags WHERE todo_id = $1', [todo.id])
          todo.tags.each { |tag| query('INSERT INTO todo_tags (todo_id, tag) VALUES ($1, $2)', [todo.id, tag.name]) }
        end
        todo
      end

      def delete(id)
        transaction do
          query('DELETE FROM todo_tags WHERE todo_id = $1', [id.to_s])
          query('DELETE FROM todos WHERE id = $1 RETURNING id', [id.to_s]).any?
        end
      end

      # Not part of the port: the composition root's test-only reset.
      def clear
        transaction do
          query('DELETE FROM todo_tags')
          query('DELETE FROM todos')
        end
        nil
      end

      private

      def transaction
        query('BEGIN')
        result = yield
        query('COMMIT')
        result
      rescue Exception # rubocop:disable Lint/RescueException -- JS errors from libpq too
        query('ROLLBACK')
        raise
      end

      # Rows come back as a JS array of plain objects. Without params,
      # pg-native uses libpq's simple protocol, which (unlike the
      # extended one) runs several statements at once, as SCHEMA needs.
      def query(sql, params = [])
        params.empty? ? `#{@client}.querySync(#{sql})` : `#{@client}.querySync(#{sql}, #{params})`
      end

      # { todo id => [tag names] } from JS rows of todo_id and tag.
      def tags_by_todo(rows)
        rows.each_with_object({}) { |row, tags| (tags[`#{row}.todo_id`] ||= []) << `#{row}.tag` }
      end

      def build(row, tag_names)
        Todo.new(id: `#{row}.id`, title: `#{row}.title`, completed: `#{row}.completed` == true, tags: tag_names)
      end
    end
  end
end
