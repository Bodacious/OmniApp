# frozen_string_literal: true

require 'js'
require_relative '../../../../../domain/ports/id_generator'

module OmniWasm
  module Adapters
    ##
    # The id generator port over the browser's Web Crypto API.
    class CryptoIdGenerator
      include Ports::IdGenerator

      def next_id
        JS.global[:crypto].call(:randomUUID).to_s
      end
    end
  end
end
