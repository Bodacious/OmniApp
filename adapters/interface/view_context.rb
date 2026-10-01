# frozen_string_literal: true

require 'cgi'

module Adapters
  module Interface
    ##
    # Everything the shared page template can see. The template uses
    # only these names, so any app layer can render it by providing them:
    #
    # [page]          which page: sign_in, sign_up, lists or list
    # [user]          the signed-in User, or nil
    # [lists]         the user's Lists
    # [list]          the open list (a TodoService::UserList), or nil
    # [todos]         the open list's todos to show, oldest first
    # [tags]          every tag in use on the open list, as TagCounts
    # [current_tag]   the tag the todos are filtered by, or nil
    # [error]         a message to show, or nil
    # [email]         the email to fill back into a sign-in form
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
      NAMES = %i[page user lists list todos tags current_tag error email stack hidden_fields stylesheet].freeze

      def self.stylesheet
        @stylesheet ||= File.read(STYLESHEET_PATH)
      end

      attr_reader(*NAMES)

      def initialize(page:, stack:, user: nil, lists: [], list: nil, todos: [], tags: [], current_tag: nil,
                     error: nil, email: nil, hidden_fields: '', stylesheet: self.class.stylesheet)
        @page = page.to_s
        @user = user
        @lists = lists
        @list = list
        @todos = todos
        @tags = tags
        @current_tag = current_tag
        @error = error
        @email = email
        @stack = stack
        @hidden_fields = hidden_fields
        @stylesheet = stylesheet
      end

      def h(text)
        CGI.escapeHTML(text.to_s)
      end

      def locals
        NAMES.to_h { |name| [name, public_send(name)] }
      end
    end
  end
end
