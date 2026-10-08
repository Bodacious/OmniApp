# frozen_string_literal: true

require 'js'
require_relative '../../../../domain/model/user'
require_relative 'tracing'
require_relative 'infrastructure/ruby_memory_list_repository'
require_relative 'infrastructure/sqlite_list_repository'

module OmniWasm
  class StackError < StandardError; end

  ##
  # The composition root for the ruby_wasm app: builds the domain's
  # ListRepository over the chosen storage, wrapped in a tracing
  # decorator so the inspector can show every call through the layers.
  #
  # Unlike the server apps, the persistence can change while the page
  # runs: #use switches to another repository. Each one is built once
  # and kept, so switching back finds its todos where you left them.
  #
  # The server apps have accounts, and users own lists. This app has no
  # accounts yet: the browser has one user, who owns one list, and the
  # UI works on that list. Their ids are fixed so that the todos kept in
  # localStorage belong to the same list after a reload.
  class CompositionRoot
    APP = 'ruby_wasm'
    INTERFACE = 'dom'

    PERSISTENCE = {
      'ruby_memory' => 'Ruby Hash',
      'sqlite_memory' => 'SQLite · memory',
      'sqlite_local_storage' => 'SQLite · localStorage'
    }.freeze

    # How the layers diagram names each storage: what it is, and where
    # it keeps the data.
    DIAGRAM = {
      'ruby_memory' => ['Ruby Hash', 'CRuby heap'],
      'sqlite_memory' => ['SQLite (wasm)', ':memory:'],
      'sqlite_local_storage' => ['SQLite (wasm)', 'localStorage']
    }.freeze

    USER = User.new(id: 'browser-user', email: 'you@this.browser', password_digest: 'none: never signs in')
    LIST_ID = 'browser-list'

    attr_reader :tracer, :persistence

    # @param persistence [String] a key of PERSISTENCE
    # @raise [StackError] for any other
    def initialize(persistence)
      @tracer = Tracer.new
      @repositories = {}
      use(persistence)
    end

    # Switches to another persistence's repository, making the
    # browser's list in it the first time.
    #
    # @param persistence [String] a key of PERSISTENCE
    # @raise [StackError] for any other
    def use(persistence)
      unless PERSISTENCE.key?(persistence)
        raise StackError, "#{persistence.inspect} is not a persistence this app has. " \
                          "Choose one of: #{PERSISTENCE.keys.join(', ')}"
      end

      @persistence = persistence
      @repositories[persistence] ||= tracer.muted do
        repository = build(persistence, tracer:)
        repository.find(LIST_ID) || repository.save(List.new(id: LIST_ID, owner_id: USER.id, name: 'Todos'))
        Traced::ListRepository.new(repository, tracer)
      end
    end

    # Every List in the current persistence, as a ListRepository.
    #
    # @return [ListRepository]
    def lists
      @repositories.fetch(persistence)
    end

    # The user the browser acts for.
    #
    # @return [User]
    def user
      USER
    end

    # The id of the one list the browser works on.
    #
    # @return [String]
    def list_id
      LIST_ID
    end

    def stack
      { 'app' => APP, 'persistence' => @repositories.fetch(persistence).persistence_name, 'interface' => INTERFACE }
    end

    def runtime
      { 'ruby' => "CRuby #{RUBY_VERSION}", 'platform' => RUBY_PLATFORM, 'sqlite' => "SQLite #{sqlite[:version]}" }
    end

    ##
    # A new, untraced repository of the given kind on a scratch store,
    # for running the repository contract without touching your todos.
    # The localStorage one runs on sessionStorage instead: same class,
    # same SQLite, different storage.
    def scratch_repository(persistence)
      case persistence
      when 'ruby_memory' then Infrastructure::RubyMemoryListRepository.new
      when 'sqlite_memory' then Infrastructure::SqliteListRepository.new(sqlite.call(:open, 'memory'), persistence)
      when 'sqlite_local_storage'
        Infrastructure::SqliteListRepository.new(sqlite.call(:open, 'session_storage'), persistence)
      end
    end

    private

    def build(persistence, tracer:)
      case persistence
      when 'ruby_memory' then Infrastructure::RubyMemoryListRepository.new(tracer:)
      when 'sqlite_memory'
        Infrastructure::SqliteListRepository.new(sqlite.call(:open, 'memory'), persistence, tracer:)
      when 'sqlite_local_storage'
        Infrastructure::SqliteListRepository.new(sqlite.call(:open, 'local_storage'), persistence, tracer:)
      end
    end

    # The SQLite facade boot.js set up.
    def sqlite
      JS.global[:omniSqlite]
    end
  end
end
