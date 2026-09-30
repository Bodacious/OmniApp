# frozen_string_literal: true

require 'erb'

module OmniWasm
  module UI
    ##
    # Renders each region of the page as HTML. The list keeps the same
    # data-testid hooks as the server-rendered templates in
    # adapters/interface/, so the same kinds of step drive both.
    module View
      extend ERB::Util

      FILTERS = { 'all' => 'All', 'active' => 'Active', 'completed' => 'Completed' }.freeze
      LAYERS = { use_case: 'use case', port: 'port', adapter: 'adapter' }.freeze

      module_function

      def badge(stack)
        stack.map { |axis, value| %(<span class="stack-badge__axis" data-axis="#{axis}">#{h(value)}</span>) }
             .join(' <span class="stack-badge__sep">/</span> ')
      end

      def runtime(runtime, boot)
        chips = [runtime['ruby'], runtime['platform'], runtime['sqlite'],
                 "domain/ loaded by require (#{boot[:files]} files)", "booted in #{boot[:ms]} ms"]
        chips.each_with_index.map do |chip, index|
          %(<span class="runtime-chip" data-testid="runtime-#{%w[ruby platform sqlite files boot][index]}">#{h(chip)}</span>)
        end.join
      end

      def error(message)
        return '' unless message

        %(<p class="todo-form__error" role="alert" data-testid="todo-error">#{h(message)}</p>)
      end

      def filters(current, counts)
        FILTERS.map do |key, label|
          selected = key == current
          %(<button type="button" class="filter#{' filter--current' if selected}" data-action="filter" ) +
            %(data-filter="#{key}" data-testid="filter-#{key}" aria-pressed="#{selected}">) +
            %(#{label} <span class="filter__count">#{counts.fetch(key)}</span></button>)
        end.join
      end

      def list(todos, filter, highlight_id)
        if todos.empty?
          message = filter == 'all' ? 'Nothing to do yet.' : "No #{filter} todos."
          return %(<p class="todo-empty" data-testid="todo-empty">#{message}</p><ul data-testid="todo-list"></ul>)
        end

        items = todos.map { |todo| item(todo, todo.id == highlight_id) }.join
        %(<ul class="todo-list" data-testid="todo-list">#{items}</ul>)
      end

      def item(todo, fresh)
        classes = ['todo-item', 'wasm-item']
        classes << 'todo-item--completed' if todo.completed?
        classes << 'wasm-item--fresh' if fresh
        check = if todo.completed?
                  %(<span class="check check--done" data-testid="todo-done-marker" aria-label="Done">✓</span>)
                else
                  %(<button type="button" class="check" data-action="complete" data-id="#{h(todo.id)}" ) +
                    %(data-testid="todo-complete-button" aria-label="Complete #{h(todo.title)}"></button>)
                end
        %(<li class="#{classes.join(' ')}" data-testid="todo-item" data-todo-id="#{h(todo.id)}" ) +
          %(data-completed="#{todo.completed?}">#{check}) +
          %(<span class="todo-item__title" data-testid="todo-item-title">#{h(todo.title)}</span>) +
          %(<button type="button" class="delete" data-action="delete" data-id="#{h(todo.id)}" ) +
          %(data-testid="todo-delete-button" aria-label="Delete #{h(todo.title)}">×</button></li>)
      end

      def summary(active_count)
        %(<span data-testid="todo-remaining">#{active_count} #{active_count == 1 ? 'item' : 'items'} left</span>)
      end

      def persistence(current, options)
        options.map do |key, label|
          selected = key == current
          %(<button type="button" class="segment#{' segment--current' if selected}" data-action="persistence" ) +
            %(data-persistence="#{key}" data-testid="persistence-#{key}" aria-pressed="#{selected}">#{h(label)}</button>)
        end.join
      end

      def trace(actions)
        return %(<li class="trace__empty">Calls across the ports appear here as you use the app.</li>) if actions.empty?

        actions.reverse.map { |span| trace_span(span, 0) }.join
      end

      def trace_span(span, depth)
        timing = span.ms ? %(<span class="trace__ms">#{format('%.2f', span.ms)} ms</span>) : ''
        detail = span.detail ? %(<span class="trace__detail#{' trace__detail--failed' if span.failed}">→ #{h(span.detail)}</span>) : ''
        line = %(<li class="trace__entry trace__entry--#{span.layer}" style="--depth: #{depth}" ) +
               %(data-testid="trace-entry" data-layer="#{span.layer}" title="#{h(span.label)}">) +
               %(<span class="trace__layer">#{LAYERS.fetch(span.layer)}</span>) +
               %(<span class="trace__label">#{h(span.label)}</span>#{detail}#{timing}</li>)
        line + span.children.map { |child| trace_span(child, depth + 1) }.join
      end

      def contract(results, label)
        return '' unless results

        passed = results.count(&:passed)
        rows = results.map do |result|
          mark = result.passed ? '✓' : '✗'
          message = result.message ? %(<span class="contract__message">#{h(result.message)}</span>) : ''
          %(<li class="contract__result contract__result--#{result.passed ? 'pass' : 'fail'}" ) +
            %(data-testid="contract-result" data-passed="#{result.passed}">) +
            %(<span class="contract__mark">#{mark}</span><code>#{h(result.name)}</code>) +
            %(<span class="trace__ms">#{format('%.1f', result.ms)} ms</span>#{message}</li>)
        end.join
        %(<p class="contract__summary" data-testid="contract-summary">#{passed}/#{results.size} passed on ) +
          %(<strong>#{h(label)}</strong>, on a scratch store</p><ol class="contract__results">#{rows}</ol>)
      end
    end
  end
end
