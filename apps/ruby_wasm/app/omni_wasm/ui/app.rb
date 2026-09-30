# frozen_string_literal: true

require 'js'
require_relative 'dom'
require_relative 'view'
require_relative '../contract_runner'

module OmniWasm
  module UI
    ##
    # The ruby_wasm app layer: turns clicks and form submits into use
    # case calls on the domain's TodoService, then re-renders. Like the
    # server apps, it asks the domain and never touches an adapter;
    # unlike them, it runs in the browser, so there are no page loads.
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

      def todo_service
        composition.todo_service
      end

      def submitted(event)
        if Dom.closest(event, "[data-testid='todo-form']")
          event.call(:preventDefault)
          add(Dom.find("[data-testid='todo-title-input']"), Dom.find("[data-testid='todo-tags-input']"))
        elsif (form = Dom.closest(event, "[data-testid='todo-tag-form']"))
          event.call(:preventDefault)
          tags = form.call(:querySelector, "[data-testid='todo-tag-input']")[:value].to_s
          act { todo_service.tag(Dom.data(form, 'id'), tags) }
          render
        end
      end

      def clicked(event)
        target = Dom.closest(event, '[data-action]')
        return unless target

        case Dom.data(target, 'action')
        when 'complete' then act { todo_service.complete(Dom.data(target, 'id')) }
        when 'untag' then act { todo_service.untag(Dom.data(target, 'id'), Dom.data(target, 'tag')) }
        when 'delete' then act { todo_service.delete(Dom.data(target, 'id')) }
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
        todo = todo_service.add(title_input[:value].to_s, tags_input[:value].to_s)
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

      def act
        @error = nil
        @fresh_id = nil
        yield
      rescue InvalidInput, TodoService::NotFound => e
        @error = e.message
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
        results = ContractRunner.new(-> { composition.scratch_repository(persistence) }).run
        @contract = [results, CompositionRoot::PERSISTENCE.fetch(persistence)]
      end

      def render
        todos = todo_service.todos(tagged: @tag)
        counts = FILTERS.transform_values { |keep| todos.count(&keep) }
        Dom.fill('list', View.list(todos.select(&FILTERS.fetch(@filter)), @filter, @tag, @fresh_id))
        Dom.fill('filters', View.filters(@filter, counts))
        Dom.fill('tag-filter', View.tag_filter(todo_service.tags, @tag))
        Dom.fill('summary', View.summary(counts.fetch('active')))
        Dom.fill('error', View.error(@error))
        Dom.fill('badge', View.badge(composition.stack))
        Dom.fill('persistence', View.persistence(composition.persistence, CompositionRoot::PERSISTENCE))
        name, store = CompositionRoot::DIAGRAM.fetch(composition.persistence)
        Dom.region('adapter-name')[:textContent] = name
        Dom.region('adapter-store')[:textContent] = store
        Dom.fill('contract', @contract ? View.contract(*@contract) : '')
        Dom.fill('trace', View.trace(composition.tracer.actions))
        light_up_diagram
      end

      # Lights up the parts of the hexagon diagram the latest action
      # went through.
      def light_up_diagram
        action = composition.tracer.actions.reverse.find do |span|
          !span.label.start_with?('TodoService#todos', 'TodoService#tags')
        end
        return unless action

        labels = flatten(action).map(&:label)
        parts = %w[ui use-case]
        parts += %w[port-repository adapter-repository] if labels.any? { |label| label.start_with?('TodoRepository') }
        parts += %w[port-ids adapter-ids] if labels.any? { |label| label.start_with?('IdGenerator') }
        Dom.pulse(parts.map { |part| "[data-part='#{part}']" }.join(','), 'lit')
      end

      def flatten(span)
        [span] + span.children.flat_map { |child| flatten(child) }
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
