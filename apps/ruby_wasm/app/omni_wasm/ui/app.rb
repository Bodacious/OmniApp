# frozen_string_literal: true

require 'js'
require_relative 'dom'
require_relative 'view'
require_relative '../contract'

module OmniWasm
  module UI
    ##
    # The ruby_wasm app layer: turns clicks and form submits into
    # changes to the browser's one List, which it fetches from the
    # domain's ListRepository and saves back, then re-renders. Like the
    # server apps, it only ever talks to the domain; unlike them, it
    # runs in the browser, so there are no page loads.
    class App
      FILTERS = {
        'all' => ->(_todo) { true },
        'active' => ->(todo) { !todo.completed? },
        'completed' => lambda(&:completed?)
      }.freeze

      def initialize(composition)
        @composition = composition
        @filter = 'all'
        @tag = nil
        @error = nil
        @fresh_id = nil
        @contract = nil
      end

      def start
        Dom.on('submit') { |event| submitted(event) }
        Dom.on('click') { |event| clicked(event) }
        render
        ready
      end

      private

      attr_reader :composition

      def lists
        composition.lists
      end

      def submitted(event)
        if Dom.closest(event, "[data-testid='todo-form']")
          event.call(:preventDefault)
          add(Dom.find("[data-testid='todo-title-input']"), Dom.find("[data-testid='todo-tags-input']"))
        elsif (form = Dom.closest(event, "[data-testid='todo-tag-form']"))
          event.call(:preventDefault)
          tags = form.call(:querySelector, "[data-testid='todo-tag-input']")[:value].to_s
          id = Dom.data(form, 'id')
          act("tag(#{Traced.short(id)}, #{tags.inspect})") { |list| list.tag(id, tags) }
          render
        end
      end

      def clicked(event)
        target = Dom.closest(event, '[data-action]')
        return unless target

        id = Dom.data(target, 'id')
        case Dom.data(target, 'action')
        when 'complete' then act("complete(#{Traced.short(id)})") { |list| list.complete(id) }
        when 'untag'
          tag = Dom.data(target, 'tag')
          act("untag(#{Traced.short(id)}, #{tag.inspect})") { |list| list.untag(id, tag) }
        when 'delete' then act("remove(#{Traced.short(id)})") { |list| list.remove(id) }
        when 'persistence' then switch_persistence(Dom.data(target, 'persistence'))
        else return ui_only(target)
        end
        render
      end

      # Actions that don't involve the domain: re-render without
      # putting the re-read in the trace.
      def ui_only(target)
        case Dom.data(target, 'action')
        when 'filter' then @filter = Dom.data(target, 'filter')
        when 'filter-tag'
          tag = Dom.data(target, 'tag')
          @tag = tag.empty? || tag == @tag ? nil : tag
        when 'run-contract' then run_contract
        when 'clear-trace' then composition.tracer.clear
        end
        composition.tracer.muted { render }
      end

      def add(title_input, tags_input)
        title = title_input[:value].to_s
        tags = tags_input[:value].to_s
        call = tags.strip.empty? ? "add(#{title.inspect})" : "add(#{title.inspect}, #{tags.inspect})"
        todo = change(call) { |list| list.add(id: lists.next_identity, title: title, tags: tags) }
        @error = nil
        @fresh_id = todo.id
        title_input[:value] = ''
        tags_input[:value] = ''
        title_input[:ariaInvalid] = 'false'
      rescue InvalidInput => e
        @error = e.message
        title_input[:ariaInvalid] = 'true'
        Dom.pulse("[data-testid='todo-title-input']", 'shake')
      ensure
        title_input.call(:focus)
        render
      end

      def act(call, &)
        @error = nil
        @fresh_id = nil
        change(call, &)
      rescue InvalidInput, NotFound => e
        @error = e.message
      end

      # Fetches the browser's list, lets the block change it, and saves
      # it, all traced as one action.
      def change(call)
        composition.tracer.span(:action, "List##{call}") do |span|
          list = lists.fetch(composition.list_id, owner: composition.user)
          result = yield list
          lists.save(list)
          result
        rescue StandardError => e
          span.detail = "raised #{e.class}: #{e.message}"
          span.failed = true
          raise
        end
      end

      def switch_persistence(persistence)
        composition.use(persistence)
        @tag = nil
        Dom.replace_query('persistence', persistence)
        @contract = nil
        @error = nil
      end

      def run_contract
        persistence = composition.persistence
        results = Contract.new(-> { composition.scratch_repository(persistence) }).results
        @contract = [results, CompositionRoot::PERSISTENCE.fetch(persistence)]
      end

      def render
        list = composition.tracer.span(:action, @tag ? "List#todos(tagged: #{@tag.inspect})" : 'List#todos') do
          lists.fetch(composition.list_id, owner: composition.user)
        end
        todos = list.todos(tagged: @tag)
        counts = FILTERS.transform_values { |keep| todos.count(&keep) }
        Dom.fill('list', View.list(todos.select(&FILTERS.fetch(@filter)), @filter, @tag, @fresh_id))
        Dom.fill('filters', View.filters(@filter, counts))
        Dom.fill('tag-filter', View.tag_filter(list.tags, @tag))
        Dom.fill('summary', View.summary(counts.fetch('active')))
        Dom.fill('error', View.error(@error))
        Dom.fill('badge', View.badge(composition.stack))
        Dom.fill('persistence', View.persistence(composition.persistence, CompositionRoot::PERSISTENCE))
        name, store = CompositionRoot::DIAGRAM.fetch(composition.persistence)
        Dom.region('storage-name')[:textContent] = name
        Dom.region('storage-store')[:textContent] = store
        Dom.fill('contract', @contract ? View.contract(*@contract) : '')
        Dom.fill('trace', View.trace(composition.tracer.actions))
        light_up_diagram
      end

      # Lights up the parts of the layers diagram the latest change went
      # through.
      def light_up_diagram
        action = composition.tracer.actions.reverse.find { |span| !span.label.start_with?('List#todos') }
        return unless action

        parts = %w[ui model]
        parts += %w[repository storage] unless action.children.empty?
        Dom.pulse(parts.map { |part| "[data-part='#{part}']" }.join(','), 'lit')
      end

      def ready
        boot = JS.global[:omniBoot]
        Dom.fill('runtime', View.runtime(composition.runtime, { files: boot[:files].to_i, ms: boot[:ms].to_i }))
        Dom.find('[data-region=controls]')[:disabled] = false
        Dom.find('[data-region=boot]')[:hidden] = true
        Dom.document[:body][:dataset][:omniReady] = 'true'
        Dom.find("[data-testid='todo-title-input']").call(:focus)
      end
    end
  end
end
