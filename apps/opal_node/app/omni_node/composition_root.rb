# frozen_string_literal: true

require 'accounts'
require 'todo_service'
require 'omni_node/node'
require 'omni_node/view_context'
require 'omni_node/session_cookie'
require 'omni_node/adapters/sql_drivers'
require 'omni_node/adapters/sql_repositories'
require 'omni_node/adapters/crypto_scrypt_password_hasher'
require 'omni_node/adapters/crypto_id_generator'

module OmniNode
  class StackError < StandardError; end

  Stack = Struct.new(:app, :persistence, :interface) do
    def to_h
      { 'app' => app, 'persistence' => persistence, 'interface' => interface }
    end
  end

  ##
  # The composition root for the Opal app: reads the stack from the
  # environment, builds this app's own adapters for it, and hands them
  # to the domain. The axes and exclusions are config/stack_matrix.yml,
  # embedded at build time as OmniNode::MATRIX.
  class CompositionRoot
    APP = 'opal_node'

    # The SQL driver for each persistence. The repositories on top are
    # the same for both (adapters/sql_repositories.rb).
    PERSISTENCE = {
      'sqlite_memory' => ->(_env) { Adapters::SqliteDriver.new(':memory:') },
      'postgres' => lambda do |env|
        url = env.call('DATABASE_URL')
        raise StackError, 'OMNI_PERSISTENCE=postgres needs DATABASE_URL' if url.nil? || url.empty?

        Adapters::PostgresDriver.new(url)
      end
    }.freeze

    ##
    # Raises StackError, before the server listens, if OMNI_* is unset,
    # unknown, excluded, meant for another app, or can't be connected.
    # +env+ is a callable from a variable's name to its value or nil.
    def self.boot(env)
      stack = Stack.new(*%w[app persistence interface].map { |axis| selected(env, axis) })
      exclusion = MATRIX['exclusions'].find do |rule|
        stack.to_h.all? { |axis, value| !rule.key?(axis) || rule[axis] == value }
      end
      raise StackError, "#{stack.to_h.values.join(' · ')} is excluded from the matrix: #{exclusion['reason']}" if exclusion
      raise StackError, "OMNI_APP=#{stack.app}, but this is the #{APP} app. Start stacks with bin/omni." unless stack.app == APP

      new(stack, env)
    end

    def self.selected(env, axis)
      name = "OMNI_#{axis.upcase}"
      value = env.call(name)
      known = MATRIX['axes'][axis]
      raise StackError, "#{name} is not set. Choose one of: #{known.join(', ')}" if value.nil? || value.empty?
      raise StackError, "#{name}=#{value} is not a known #{axis}. Choose one of: #{known.join(', ')}" unless known.include?(value)

      value
    end

    attr_reader :accounts, :todo_service, :session, :stack

    def initialize(stack, env)
      connect = PERSISTENCE.fetch(stack.persistence) do
        raise StackError, "opal_node has no persistence adapter for #{stack.persistence}"
      end
      begin
        @store = Adapters::SqlStore.new(connect.call(env))
      rescue StackError
        raise
      rescue Exception => e # rubocop:disable Lint/RescueException -- JS errors from the drivers
        raise StackError, "Could not open #{stack.persistence}: #{e.message}"
      end

      @template = Template["omni/#{stack.interface}/index"]
      raise StackError, "opal_node has no compiled template for interface #{stack.interface}" unless @template

      ids = Adapters::CryptoIdGenerator.new
      @accounts = Accounts.new(users: @store.users, password_hasher: Adapters::CryptoScryptPasswordHasher.new,
                               id_generator: ids)
      @todo_service = TodoService.new(lists: @store.lists, todos: @store.todos, id_generator: ids)
      @session = SessionCookie.new(env.call('SESSION_SECRET'))
      @test_mode = env.call('OMNI_ENV') == 'test'
      # What is running, read back from what was built.
      @stack = Stack.new(APP, @store.persistence_name, stack.interface)
    end

    def health
      stack.to_h
    end

    def test_mode?
      @test_mode
    end

    # Test-only plumbing, not a use case: empties the store directly.
    def reset!
      raise StackError, 'reset! only exists when OMNI_ENV=test' unless test_mode?

      @store.clear
    end

    # The page (sign_in, sign_up, lists or list) for the signed-in +user+,
    # as in the Ruby composition root: for the list page, the open +list+
    # (a TodoService::UserList) with only the todos tagged +tag+ if one is
    # given. A malformed +tag+ shows every todo, with the domain's message.
    def render_page(page, user: nil, list: nil, tag: nil, error: nil, email: nil)
      todos = []
      tags = []
      current_tag = nil
      if list
        begin
          current_tag = tag.nil? || tag.empty? ? nil : Tag.new(tag).name
        rescue InvalidInput => e
          error ||= e.message
        end
        todos = list.todos(tagged: current_tag)
        tags = list.tags
      end
      @template.render(ViewContext.new(page: page, user: user, lists: user ? todo_service.lists(user) : [],
                                       list: list, todos: todos, tags: tags, current_tag: current_tag,
                                       error: error, email: email, stack: stack))
    end
  end
end
