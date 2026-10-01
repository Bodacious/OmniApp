# frozen_string_literal: true

require 'js'
require_relative '../../../../domain/todo_service'
require_relative 'tracing'
require_relative 'adapters/ruby_memory_list_repository'
require_relative 'adapters/ruby_memory_todo_repository'
require_relative 'adapters/sqlite_todo_repository'
require_relative 'adapters/crypto_id_generator'

module OmniWasm
  class StackError < StandardError; end

  ##
  # The composition root for the ruby_wasm app: builds the adapters and
  # hands them to the domain, wrapped in tracing decorators so the
  # inspector can show every call across the ports.
  #
  # Unlike the server apps, the persistence can change while the page
  # runs: #use builds a new TodoService around another adapter. Each
  # adapter is built once and kept, so switching back finds its todos
  # where you left them.
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

    # How the hexagon diagram names each adapter: what it is, and where
    # it keeps the data.
    DIAGRAM = {
      'ruby_memory' => ['Ruby Hash', 'CRuby heap'],
      'sqlite_memory' => ['SQLite (wasm)', ':memory:'],
      'sqlite_local_storage' => ['SQLite (wasm)', 'localStorage']
    }.freeze

    USER = User.new(id: 'browser-user', email: 'you@this.browser', password_digest: 'none: never signs in')
    LIST = List.new(id: 'browser-list', owner_id: USER.id, name: 'Todos')

    attr_reader :tracer, :persistence, :list

    def initialize(persistence)
      @tracer = Tracer.new
      @id_generator = Traced::IdGenerator.new(Adapters::CryptoIdGenerator.new, tracer)
      @lists = Adapters::RubyMemoryListRepository.new
      @lists.save(LIST)
      @repositories = {}
      use(persistence)
    end

    # Rewires the domain onto another persistence adapter.
    def use(persistence)
      unless PERSISTENCE.key?(persistence)
        raise StackError, "#{persistence.inspect} is not a persistence this app has. " \
                          "Choose one of: #{PERSISTENCE.keys.join(', ')}"
      end

      @persistence = persistence
      repository = @repositories[persistence] ||= Traced::TodoRepository.new(build(persistence, tracer:), tracer)
      todo_service = TodoService.new(lists: @lists, todos: repository, id_generator: @id_generator)
      @list = Traced::UserList.new(todo_service.list(USER, LIST.id), tracer)
    end

    def stack
      { 'app' => APP, 'persistence' => @repositories.fetch(persistence).persistence_name, 'interface' => INTERFACE }
    end

    def runtime
      { 'ruby' => "CRuby #{RUBY_VERSION}", 'platform' => RUBY_PLATFORM, 'sqlite' => "SQLite #{sqlite[:version]}" }
    end

    ##
    # A new, untraced adapter of the given kind on a scratch store, for
    # running the port contract without touching your todos. The
    # localStorage adapter runs on sessionStorage instead: same class,
    # same SQLite, different storage.
    def scratch_repository(persistence)
      case persistence
      when 'ruby_memory' then Adapters::RubyMemoryTodoRepository.new
      when 'sqlite_memory' then Adapters::SqliteTodoRepository.new(sqlite.call(:open, 'memory'), persistence)
      when 'sqlite_local_storage'
        Adapters::SqliteTodoRepository.new(sqlite.call(:open, 'session_storage'), persistence)
      end
    end

    private

    def build(persistence, tracer:)
      case persistence
      when 'ruby_memory' then Adapters::RubyMemoryTodoRepository.new(tracer:)
      when 'sqlite_memory' then Adapters::SqliteTodoRepository.new(sqlite.call(:open, 'memory'), persistence, tracer:)
      when 'sqlite_local_storage'
        Adapters::SqliteTodoRepository.new(sqlite.call(:open, 'local_storage'), persistence, tracer:)
      end
    end

    # The SQLite facade boot.js set up.
    def sqlite
      JS.global[:omniSqlite]
    end
  end
end
