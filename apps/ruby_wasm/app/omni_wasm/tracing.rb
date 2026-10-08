# frozen_string_literal: true

require_relative '../../../../domain/model/list_repository'

module OmniWasm
  ##
  # Records what passes through the layers, for the inspector: each
  # action the UI asks of a List, each repository call made for it, and
  # what the storage did underneath. Spans nest, so one action reads as
  # a small tree:
  #
  #   List#add("Buy milk")               action
  #     ListRepository#fetch(browser-)   repository
  #       ListRepository#find(browser-)  repository
  #         SQL SELECT … FROM lists …    storage
  #     ListRepository#next_identity     repository
  #       crypto.randomUUID()            storage
  #     ListRepository#save(List …)      repository
  #       SQL INSERT INTO todos …        storage
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
    # the app sent through the layers on anyone's behalf.
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
  # Each one is what it wraps (the repository includes ListRepository),
  # so the domain can't tell it's there.
  module Traced
    def self.short(id)
      id.to_s[0, 8]
    end

    ##
    # Wraps a ListRepository. The storage it wraps notes what it does
    # underneath (SQL, Hash calls) into the same Tracer.
    class ListRepository
      include ::ListRepository

      # @param repository [::ListRepository]
      # @param tracer [Tracer]
      def initialize(repository, tracer)
        @repository = repository
        @tracer = tracer
      end

      def persistence_name
        @repository.persistence_name
      end

      def next_identity
        repository('next_identity') { |span| @repository.next_identity.tap { |id| span.detail = Traced.short(id) } }
      end

      # The domain's own method, built on #find: traced so the inspector
      # shows the ownership check around the lookup.
      def fetch(id, owner:)
        repository("fetch(#{Traced.short(id)})") { super }
      end

      def find(id)
        repository("find(#{Traced.short(id)})") do |span|
          @repository.find(id).tap { |list| span.detail = list ? "#{list.todos.size} todos" : 'nil' }
        end
      end

      def owned_by(user)
        repository("owned_by(User #{Traced.short(user.id)})") { @repository.owned_by(user) }
      end

      def save(list)
        repository("save(List #{Traced.short(list.id)})") { @repository.save(list) }
      end

      def remove(list)
        repository("remove(List #{Traced.short(list.id)})") { @repository.remove(list) }
      end

      private

      def repository(call, &)
        @tracer.span(:repository, "ListRepository##{call}", &)
      end
    end
  end
end
