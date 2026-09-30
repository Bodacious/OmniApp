# frozen_string_literal: true

module OmniNode
  ##
  # What the shared ERB template sees when Opal renders it: the same
  # names as adapters/interface/view_context.rb on the Ruby side. The
  # compiled template runs with an instance of this as its self.
  class ViewContext
    ESCAPES = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#39;' }.freeze

    attr_reader :todos, :error, :stack

    def initialize(todos:, stack:, error: nil)
      @todos = todos
      @stack = stack
      @error = error
    end

    # No CSRF token outside Rails.
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
