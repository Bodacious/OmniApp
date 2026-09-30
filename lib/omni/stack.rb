# frozen_string_literal: true

module Omni
  ##
  # Raised at boot when the selected stack is missing, unknown, excluded
  # or can't be wired up. Its message says what to fix.
  class StackError < StandardError; end

  ##
  # One cell of the matrix: an app layer, a persistence adapter and an
  # interface.
  Stack = Struct.new(:app, :persistence, :interface, keyword_init: true) do
    def label
      "#{app} · #{persistence} · #{interface}"
    end

    def to_h
      { 'app' => app, 'persistence' => persistence, 'interface' => interface }
    end
  end
end
