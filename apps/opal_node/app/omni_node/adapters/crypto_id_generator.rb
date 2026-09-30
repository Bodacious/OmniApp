# frozen_string_literal: true

# backtick_javascript: true

require 'ports/id_generator'
require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The id generator port for Node: random UUIDs from node:crypto.
    class CryptoIdGenerator
      include Ports::IdGenerator

      def initialize
        @crypto = Node.require_module('node:crypto')
      end

      def next_id
        `#{@crypto}.randomUUID()`
      end
    end
  end
end
