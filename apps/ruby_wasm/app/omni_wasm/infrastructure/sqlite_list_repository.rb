# frozen_string_literal: true

require 'js'
require_relative '../../../../../domain/model/list_repository'

module OmniWasm
  module Infrastructure
    ##
    # The domain's ListRepository over SQLite compiled to WebAssembly,
    # through the synchronous facade public/boot.js puts on
    # window.omniSqlite. The same class serves two persistences; only
    # the database handed in differs (in memory, or kept in
    # localStorage).
    #
    # A List is stored across three tables, as in the server
    # repositories: lists, a row per todo, and a row per tag on a todo.
    # #save writes the whole aggregate in one transaction.
    class SqliteListRepository
      include ::ListRepository

      SCHEMA = [<<~SQL, <<~SQL, <<~SQL].freeze
        CREATE TABLE IF NOT EXISTS lists (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          owner_id TEXT NOT NULL,
          name TEXT NOT NULL
        )
      SQL
        CREATE TABLE IF NOT EXISTS todos (
          position INTEGER PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          list_id TEXT,
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

      UPSERT_LIST = <<~SQL
        INSERT INTO lists (id, owner_id, name) VALUES (?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET name = excluded.name
      SQL
      UPSERT_TODO = <<~SQL
        INSERT INTO todos (id, list_id, title, completed) VALUES (?, ?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET title = excluded.title, completed = excluded.completed
      SQL
      DELETE_TAGS = 'DELETE FROM todo_tags WHERE todo_id IN (SELECT id FROM todos WHERE list_id = ?)'

      attr_reader :persistence_name

      # @param database [JS::Object] a database from window.omniSqlite.open
      # @param persistence_name [String]
      # @param tracer [Tracer, nil] told about each statement, for the inspector
      def initialize(database, persistence_name, tracer: nil)
        @database = database
        @persistence_name = persistence_name
        @tracer = tracer
        SCHEMA.each { |statement| query(statement) }
        add_list_id
      end

      def next_identity
        @tracer&.note(:storage, 'crypto.randomUUID()')
        JS.global[:crypto].call(:randomUUID).to_s
      end

      def find(id)
        build(query('SELECT id, owner_id, name FROM lists WHERE id = ?', id.to_s)).first
      end

      def owned_by(user)
        build(query('SELECT id, owner_id, name FROM lists WHERE owner_id = ? ORDER BY position', user.id))
      end

      def save(list)
        transaction do
          query(UPSERT_LIST, list.id, list.owner_id, list.name)
          query(DELETE_TAGS, list.id)
          kept = list.todos.map(&:id)
          query('SELECT id FROM todos WHERE list_id = ?', list.id).each do |row|
            query('DELETE FROM todos WHERE id = ?', row[:id].to_s) unless kept.include?(row[:id].to_s)
          end
          list.todos.each do |todo|
            query(UPSERT_TODO, todo.id, list.id, todo.title, todo.completed? ? 1 : 0)
            todo.tags.each { |tag| query('INSERT INTO todo_tags (todo_id, tag) VALUES (?, ?)', todo.id, tag.name) }
          end
        end
        list
      end

      def remove(list)
        transaction do
          query(DELETE_TAGS, list.id)
          query('DELETE FROM todos WHERE list_id = ?', list.id)
          query('DELETE FROM lists WHERE id = ?', list.id)
        end
        nil
      end

      # Empties every table, so the contract runner starts clean; not
      # part of the repository.
      def clear
        transaction do
          query('DELETE FROM todo_tags')
          query('DELETE FROM todos')
          query('DELETE FROM lists')
        end
        nil
      end

      private

      # A todos table kept in localStorage from before todos belonged to
      # lists has no list_id column yet.
      def add_list_id
        return if query('PRAGMA table_info(todos)').any? { |column| column[:name].to_s == 'list_id' }

        query('ALTER TABLE todos ADD COLUMN list_id TEXT')
      end

      # Rows come back as a JS array of plain objects.
      def query(sql, *bind)
        @tracer&.note(:storage, "SQL #{sql.split.join(' ')}")
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

      # Whole Lists from rows of lists, each with its todos and their tags.
      def build(rows)
        rows.map do |row|
          list_id = row[:id].to_s
          tags = {}
          query(<<~SQL, list_id).each { |tag| (tags[tag[:todo_id].to_s] ||= []) << tag[:tag].to_s }
            SELECT todo_tags.todo_id, todo_tags.tag FROM todo_tags
            JOIN todos ON todos.id = todo_tags.todo_id WHERE todos.list_id = ?
          SQL
          todos = query('SELECT id, title, completed FROM todos WHERE list_id = ? ORDER BY position', list_id)
                  .map do |todo|
            Todo.new(id: todo[:id].to_s, title: todo[:title].to_s, completed: todo[:completed].to_i == 1,
                     tags: tags.fetch(todo[:id].to_s, []))
          end
          List.new(id: list_id, owner_id: row[:owner_id].to_s, name: row[:name].to_s, todos: todos)
        end
      end
    end
  end
end
