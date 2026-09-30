# frozen_string_literal: true

require_relative '../../../../domain/ports/todo_repository'
require_relative '../../../../domain/ports/id_generator'

module OmniWasm
  ##
  # Records what crosses the hexagon's boundary, for the inspector:
  # each use case the UI calls, each port call the domain makes during
  # it, and what the adapter did underneath. Spans nest, so one action
  # reads as a small tree:
  #
  #   TodoService#add("Buy milk")     use case
  #     IdGenerator#next_id           port
  #     TodoRepository#save(Todo …)   port
  #       SQL INSERT INTO todos …     adapter
  class Tracer
    Span = Struct.new(:layer, :label, :detail, :ms, :children, :failed)
    KEEP = 25

    attr_reader :actions

    def initialize
      @actions = []
      @open = []
    end

    def span(layer, label)
      span = Span.new(layer, label, nil, nil, [])
      attach(span)
      @open.push(span)
      started = now
      yield span
    ensure
      span.ms = now - started if started
      @open.pop
    end

    def note(layer, label)
      attach(Span.new(layer, label, nil, nil, []))
    end

    def clear
      @actions.clear
    end

    # Runs the block without recording anything: for re-renders after
    # UI-only actions (a filter, a contract run), which are not traffic
    # the app sent across the ports on anyone's behalf.
    def muted
      @muted = true
      yield
    ensure
      @muted = false
    end

    private

    def attach(span)
      return if @muted

      if @open.empty?
        @actions << span
        @actions.shift while @actions.size > KEEP
      else
        @open.last.children << span
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    end
  end

  ##
  # Decorators that wrap the real collaborators and report to a Tracer.
  # Each one implements the same interface as what it wraps (the ports
  # include the port modules), so the domain can't tell they're there.
  module Traced
    def self.short(id)
      id.to_s[0, 8]
    end

    # Wraps the domain's TodoService: the calls the UI makes.
    class TodoService
      def initialize(service, tracer)
        @service = service
        @tracer = tracer
      end

      def todos(tagged: nil)
        call = tagged ? "todos(tagged: #{tagged.inspect})" : 'todos'
        trace(call) { |span| @service.todos(tagged: tagged).tap { |todos| span.detail = "#{todos.size} todos" } }
      end

      def tags
        trace('tags') { |span| @service.tags.tap { |tags| span.detail = "#{tags.size} tags" } }
      end

      def add(title, tags = [])
        call = tags.to_s.strip.empty? ? "add(#{title.inspect})" : "add(#{title.inspect}, #{tags.inspect})"
        trace(call) { |span| @service.add(title, tags).tap { |todo| span.detail = "Todo #{Traced.short(todo.id)}" } }
      end

      def complete(id)
        trace("complete(#{Traced.short(id)})") { @service.complete(id) }
      end

      def tag(id, tags)
        trace("tag(#{Traced.short(id)}, #{tags.inspect})") do |span|
          @service.tag(id, tags).tap { |todo| span.detail = todo.tags.map { |tag| "##{tag}" }.join(' ') }
        end
      end

      def untag(id, tag)
        trace("untag(#{Traced.short(id)}, #{tag.inspect})") { @service.untag(id, tag) }
      end

      def delete(id)
        trace("delete(#{Traced.short(id)})") { @service.delete(id) }
      end

      private

      def trace(call)
        @tracer.span(:use_case, "TodoService##{call}") do |span|
          yield span
        rescue StandardError => e
          span.detail = "raised #{e.class}: #{e.message}"
          span.failed = true
          raise
        end
      end
    end

    class TodoRepository
      include Ports::TodoRepository

      def initialize(repository, tracer)
        @repository = repository
        @tracer = tracer
      end

      def persistence_name
        @repository.persistence_name
      end

      def all
        port('all') { |span| @repository.all.tap { |todos| span.detail = "#{todos.size} todos" } }
      end

      def find(id)
        port("find(#{Traced.short(id)})") { |span| @repository.find(id).tap { |todo| span.detail = todo ? 'found' : 'nil' } }
      end

      def save(todo)
        port("save(Todo #{Traced.short(todo.id)})") { @repository.save(todo) }
      end

      def delete(id)
        port("delete(#{Traced.short(id)})") { |span| @repository.delete(id).tap { |deleted| span.detail = deleted.to_s } }
      end

      private

      def port(call, &)
        @tracer.span(:port, "TodoRepository##{call}", &)
      end
    end

    class IdGenerator
      include Ports::IdGenerator

      def initialize(id_generator, tracer)
        @id_generator = id_generator
        @tracer = tracer
      end

      def next_id
        @tracer.span(:port, 'IdGenerator#next_id') do |span|
          @tracer.note(:adapter, 'crypto.randomUUID()')
          @id_generator.next_id.tap { |id| span.detail = Traced.short(id) }
        end
      end
    end
  end
end
