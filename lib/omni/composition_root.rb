# frozen_string_literal: true

require_relative 'matrix'
require_relative '../../domain/todo_list'
require_relative '../../adapters/persistence/sql'
require_relative '../../adapters/ids/secure_random_id_generator'
require_relative '../../adapters/interface/templates'
require_relative '../../adapters/interface/view_context'

module Omni
  ##
  # The composition root for the Ruby app layers, Rails and Sinatra:
  # the one place that reads the stack from the environment, builds the
  # adapters it names and hands them to the domain. An app layer gets a
  # TodoList to call, a template to render and nothing else.
  class CompositionRoot
    ##
    # Wires up the stack selected by OMNI_APP, OMNI_PERSISTENCE and
    # OMNI_INTERFACE for the named app. Raises StackError, before
    # anything serves a request, if the selection is missing, unknown,
    # excluded, meant for a different app, or can't be connected.
    def self.boot(app:, env: ENV)
      stack = Matrix.load.stack_from_env(env)
      unless stack.app == app
        raise StackError, "OMNI_APP=#{stack.app}, but this is the #{app} app. " \
                          'Start stacks with bin/omni, which boots the app OMNI_APP names.'
      end

      new(app: app, stack: stack, env: env)
    rescue Adapters::Persistence::Sql::ConfigurationError,
           Adapters::Interface::Templates::ConfigurationError => e
      raise StackError, e.message
    end

    attr_reader :todo_list, :template_path

    def initialize(app:, stack:, env:)
      @app = app
      @repository = Adapters::Persistence::Sql.todo_repository(stack.persistence, env)
      @todo_list = TodoList.new(repository: @repository,
                                id_generator: Adapters::Ids::SecureRandomIdGenerator.new)
      @template_path = Adapters::Interface::Templates.page(stack.interface)
      @test_mode = env['OMNI_ENV'] == 'test'
    end

    ##
    # The stack that is actually running, read back from what was
    # built rather than echoed from the environment: the app that
    # booted, the database the repository is connected to, and the
    # template engine that was loaded.
    def stack
      Stack.new(app: @app,
                persistence: @repository.persistence_name,
                interface: File.extname(template_path).delete('.'))
    end

    def health
      stack.to_h
    end

    # True when OMNI_ENV=test, which mounts the reset endpoint.
    def test_mode?
      @test_mode
    end

    ##
    # A Rack endpoint that deletes every todo, for the specs to call
    # before each scenario. It's plumbing, not a use case, so it talks
    # to the adapter directly. Apps mount it only when test_mode?.
    def test_reset_endpoint
      raise StackError, 'The reset endpoint only exists when OMNI_ENV=test' unless test_mode?

      repository = @repository
      lambda do |env|
        next [405, { 'allow' => 'POST' }, []] unless env['REQUEST_METHOD'] == 'POST'

        repository.clear
        [204, {}, []]
      end
    end

    def view_context(error: nil, hidden_fields: '')
      Adapters::Interface::ViewContext.new(todos: todo_list.todos, stack: stack,
                                           error: error, hidden_fields: hidden_fields)
    end
  end
end
