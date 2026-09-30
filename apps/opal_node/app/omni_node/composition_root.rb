# frozen_string_literal: true

require 'todo_list'
require 'omni_node/node'
require 'omni_node/view_context'
require 'omni_node/adapters/sqlite_todo_repository'
require 'omni_node/adapters/postgres_todo_repository'
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

    PERSISTENCE = {
      'sqlite_memory' => ->(_env) { Adapters::SqliteTodoRepository.new(':memory:') },
      'postgres' => lambda do |env|
        url = env.call('DATABASE_URL')
        raise StackError, 'OMNI_PERSISTENCE=postgres needs DATABASE_URL' if url.nil? || url.empty?

        Adapters::PostgresTodoRepository.new(url)
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

    attr_reader :todo_list, :stack

    def initialize(stack, env)
      connect = PERSISTENCE.fetch(stack.persistence) do
        raise StackError, "opal_node has no persistence adapter for #{stack.persistence}"
      end
      begin
        @repository = connect.call(env)
      rescue StackError
        raise
      rescue Exception => e # rubocop:disable Lint/RescueException -- JS errors from the drivers
        raise StackError, "Could not open #{stack.persistence}: #{e.message}"
      end

      @template = Template["omni/#{stack.interface}/index"]
      raise StackError, "opal_node has no compiled template for interface #{stack.interface}" unless @template

      @todo_list = TodoList.new(repository: @repository, id_generator: Adapters::CryptoIdGenerator.new)
      @test_mode = env.call('OMNI_ENV') == 'test'
      # What is running, read back from what was built.
      @stack = Stack.new(APP, @repository.persistence_name, stack.interface)
    end

    def health
      stack.to_h
    end

    def test_mode?
      @test_mode
    end

    # Test-only plumbing, not a use case: talks to the adapter directly.
    def reset!
      raise StackError, 'reset! only exists when OMNI_ENV=test' unless test_mode?

      @repository.clear
    end

    def render_page(error: nil)
      @template.render(ViewContext.new(todos: todo_list.todos, stack: stack, error: error))
    end
  end
end
