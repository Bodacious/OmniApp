# frozen_string_literal: true

module OmniNode
  ##
  # What the shared ERB template sees when Opal renders it: the same
  # names as adapters/interface/view_context.rb on the Ruby side. The
  # compiled template runs with an instance of this as its self.
  class ViewContext
    ESCAPES = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#39;' }.freeze

    attr_reader :page, :user, :lists, :list, :todos, :tags, :current_tag, :error, :email, :stack

    def initialize(page:, stack:, user: nil, lists: [], list: nil, todos: [], tags: [], current_tag: nil,
                   error: nil, email: nil)
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
    end

    # No CSRF token outside Rails: the session cookie is SameSite=Lax.
    def hidden_fields
      ''
    end

    # adapters/interface/omni.css, embedded at build time.
    def stylesheet
      STYLESHEET
    end

    def h(text)
      text.to_s.gsub(/[&<>"']/) { |char| ESCAPES[char] }
    end
  end
end
