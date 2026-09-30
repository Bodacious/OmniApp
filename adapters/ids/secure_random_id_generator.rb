# frozen_string_literal: true

require 'securerandom'
require_relative '../../domain/ports/id_generator'

module Adapters
  module Ids
    ##
    # The id generator port for MRI: random UUIDs.
    class SecureRandomIdGenerator
      include Ports::IdGenerator

      def next_id
        SecureRandom.uuid
      end
    end
  end
end
