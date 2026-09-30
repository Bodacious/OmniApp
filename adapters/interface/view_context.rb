# frozen_string_literal: true

require 'cgi'

module Adapters
  module Interface
    ##
    # Everything the shared templates can see. The templates use only
    # these names, so any app layer can render them by providing them:
    #
    # [todos]         the domain's Todo objects to show, oldest first
    # [tags]          every tag in use, as TodoService::TagCounts
    # [current_tag]   the tag the list is filtered by, or nil
    # [error]         a message to show, or nil
    # [stack]         the running stack (app, persistence, interface)
    # [hidden_fields] raw HTML added to every form; Rails puts its CSRF
    #                 token here, other app layers leave it empty
    # [stylesheet]    the shared CSS, inlined into the page
    # [h(text)]       HTML-escapes text (ERB templates only; Slim
    #                 escapes by itself)
    #
    # Sinatra renders with an instance of this as the template's self.
    # Rails passes #locals and uses ActionView's own h. The Opal app has
    # its own context with the same names (apps/opal_node).
    #
    # The ERB template is also compiled by Opal::ERB, whose compiler is a
    # few regular expressions. So it sticks to plain <% %> and <%= %>
    # tags (no <%==, no -%>, no multi-line comments) and escapes with h()
    # explicitly, because Opal's <%= %> doesn't escape.
    class ViewContext
      STYLESHEET_PATH = File.expand_path('omni.css', __dir__)

      def self.stylesheet
        @stylesheet ||= File.read(STYLESHEET_PATH)
      end

      attr_reader :todos, :tags, :current_tag, :error, :stack, :hidden_fields, :stylesheet

      def initialize(todos:, stack:, tags: [], current_tag: nil, error: nil, hidden_fields: '',
                     stylesheet: self.class.stylesheet)
        @todos = todos
        @tags = tags
        @current_tag = current_tag
        @error = error
        @stack = stack
        @hidden_fields = hidden_fields
        @stylesheet = stylesheet
      end

      def h(text)
        CGI.escapeHTML(text.to_s)
      end

      def locals
        { todos: todos, tags: tags, current_tag: current_tag, error: error, stack: stack,
          hidden_fields: hidden_fields, stylesheet: stylesheet }
      end
    end
  end
end
