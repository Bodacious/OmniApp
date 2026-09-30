# frozen_string_literal: true

# backtick_javascript: true

module OmniNode
  ##
  # The few Node APIs the app layer needs, wrapped so the rest of the
  # app reads as Ruby. JS interop lives in apps/opal_node and nowhere
  # else; the domain never sees any of it.
  module Node
    # Node's require. The bundle runs as a CommonJS script.
    def self.require_module(name)
      `require(#{name})`
    end

    # An environment variable, or nil when it's unset.
    def self.env(name)
      value = `process.env[#{name}]`
      `#{value} == null` ? nil : value
    end

    def self.exit(status)
      `process.exit(#{status})`
    end

    # JS null and undefined become nil; everything else passes through.
    def self.to_ruby(value)
      `#{value} == null` ? nil : value
    end
  end
end
