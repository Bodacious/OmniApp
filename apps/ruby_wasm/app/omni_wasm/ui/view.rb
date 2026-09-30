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

      def list(todos, filter, tag, highlight_id)
        if todos.empty?
          described = [filter == 'all' ? nil : filter, 'todos', tag ? "tagged ##{tag}" : nil].compact.join(' ')
          message = filter == 'all' && tag.nil? ? 'Nothing to do yet.' : "No #{described}."
          return %(<p class="todo-empty" data-testid="todo-empty">#{h(message)}</p><ul data-testid="todo-list"></ul>)
        end

        items = todos.map { |todo| item(todo, todo.id == highlight_id) }.join
        %(<ul class="todo-list" data-testid="todo-list">#{items}</ul>)
      end

      def item(todo, fresh)
        classes = ['todo-item', 'wasm-item']
        classes << 'todo-item--completed' if todo.completed?
        classes << 'wasm-item--fresh' if fresh
        %(<li class="#{classes.join(' ')}" data-testid="todo-item" data-todo-id="#{h(todo.id)}" ) +
          %(data-completed="#{todo.completed?}">#{check(todo)}<span class="todo-item__main">) +
          %(<span class="todo-item__title" data-testid="todo-item-title">#{h(todo.title)}</span>) +
          %(<span class="todo-item__tags">#{todo.tags.map { |tag| chip(todo, tag) }.join}#{tag_form(todo)}</span>) +
          %(</span><button type="button" class="delete" data-action="delete" data-id="#{h(todo.id)}" ) +
          %(data-testid="todo-delete-button" aria-label="Delete #{h(todo.title)}">×</button></li>)
      end

      def check(todo)
        return %(<span class="check check--done" data-testid="todo-done-marker" aria-label="Done">✓</span>) if todo.completed?

        %(<button type="button" class="check" data-action="complete" data-id="#{h(todo.id)}" ) +
          %(data-testid="todo-complete-button" aria-label="Complete #{h(todo.title)}"></button>)
      end

      def chip(todo, tag)
        %(<span class="tag" data-testid="todo-tag" data-tag="#{h(tag.name)}">) +
          %(<button type="button" class="tag__name" data-action="filter-tag" data-tag="#{h(tag.name)}">##{h(tag.name)}</button>) +
          %(<button type="button" class="tag__remove-button" data-action="untag" data-id="#{h(todo.id)}" ) +
          %(data-tag="#{h(tag.name)}" data-testid="todo-untag-button" aria-label="Remove tag #{h(tag.name)}">×</button></span>)
      end

      def tag_form(todo)
        %(<form class="tag-add" data-testid="todo-tag-form" data-id="#{h(todo.id)}">) +
          %(<input class="tag-add__input" name="tags" type="text" placeholder="+ tag" autocomplete="off" ) +
          %(aria-label="Add tags to #{h(todo.title)}" data-testid="todo-tag-input">) +
          %(<button class="tag-add__button" type="submit" data-testid="todo-tag-submit">Tag</button></form>)
      end

      def tag_filter(tag_counts, current)
        return '' if tag_counts.empty?

        links = tag_counts.map do |count|
          name = count.tag.name
          selected = name == current
          %(<button type="button" class="tag-filter__tag#{' tag-filter__tag--current' if selected}" ) +
            %(data-action="filter-tag" data-tag="#{h(name)}" data-testid="tag-filter-link" aria-pressed="#{selected}">) +
            %(##{h(name)} <span class="tag-filter__count">#{count.todo_count}</span></button>)
        end
        clear = if current
                  %(<button type="button" class="tag-filter__clear" data-action="filter-tag" data-tag="" ) +
                    %(data-testid="tag-filter-clear">Show all</button>)
                end
        %(<span class="tag-filter__label">Tags</span>#{links.join}#{clear})
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
