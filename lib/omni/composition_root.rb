# frozen_string_literal: true

require_relative 'matrix'
require_relative '../../infrastructure/sql'
require_relative '../../infrastructure/scrypt_password_hasher'
require_relative '../../presentation/templates'
require_relative '../../presentation/view_context'

module Omni
  ##
  # The composition root for the Ruby app layers, Rails and Sinatra:
  # the one place that reads the stack from the environment and builds
  # the infrastructure it names. An app layer gets the domain's two
  # repositories (users and lists), the password hasher a User needs,
  # a template to render and nothing else.
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
    rescue Infrastructure::Sql::ConfigurationError, Presentation::Templates::ConfigurationError => e
      raise StackError, e.message
    end

    attr_reader :password_hasher, :template_path

    def initialize(app:, stack:, env:)
      @app = app
      @store = Infrastructure::Sql.store(stack.persistence, env)
      @password_hasher = Infrastructure::ScryptPasswordHasher.new
      @template_path = Presentation::Templates.page(stack.interface)
      @test_mode = env['OMNI_ENV'] == 'test'
    end

    # Every User, as a UserRepository.
    #
    # @return [UserRepository]
    def users
      @store.users
    end

    # Every List, as a ListRepository.
    #
    # @return [ListRepository]
    def lists
      @store.lists
    end

    ##
    # The stack that is actually running, read back from what was
    # built rather than echoed from the environment: the app that
    # booted, the database the repositories are connected to, and the
    # template engine that was loaded.
    def stack
      Stack.new(app: @app,
                persistence: @store.persistence_name,
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
    # A Rack endpoint that deletes every user, list and todo, for the
    # specs to call before each scenario. It's plumbing, not part of the
    # domain, so it empties the store directly. Apps mount it only when
    # test_mode?.
    def test_reset_endpoint
      raise StackError, 'The reset endpoint only exists when OMNI_ENV=test' unless test_mode?

      store = @store
      lambda do |env|
        next [405, { 'allow' => 'POST' }, []] unless env['REQUEST_METHOD'] == 'POST'

        store.clear
        [204, {}, []]
      end
    end

    ##
    # What the page template needs for +page+ (sign_in, sign_up, lists
    # or list): the signed-in +user+, their lists, and for the list page
    # the open +list+ with its todos, only those tagged +tag+ if one is
    # given. A malformed +tag+ shows every
    # todo, with the domain's message.
    def view_context(page, user: nil, list: nil, tag: nil, error: nil, email: nil, hidden_fields: '')
      todos = []
      tags = []
      current_tag = nil
      if list
        begin
          current_tag = tag.to_s.empty? ? nil : Tag.new(tag).name
        rescue InvalidInput => e
          error ||= e.message
        end
        todos = list.todos(tagged: current_tag)
        tags = list.tags
      end
      Presentation::ViewContext.new(
        page: page, user: user, lists: user ? lists.owned_by(user) : [], list: list,
        todos: todos, tags: tags, current_tag: current_tag, error: error, email: email,
        stack: stack, hidden_fields: hidden_fields
      )
    end
  end
end
