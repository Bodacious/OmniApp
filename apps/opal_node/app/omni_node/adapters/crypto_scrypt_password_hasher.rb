# frozen_string_literal: true

# backtick_javascript: true

require 'ports/password_hasher'
require 'omni_node/node'

module OmniNode
  module Adapters
    ##
    # The password hasher port over node:crypto's scryptSync, which is
    # synchronous, like the port. Digests use the same format as the
    # Ruby adapter (adapters/passwords/scrypt_password_hasher.rb):
    #
    #   scrypt$16384$8$1$<salt, base64>$<hash, base64>
    #
    # so an account made on a Ruby stack signs in here, and vice versa.
    class CryptoScryptPasswordHasher
      include Ports::PasswordHasher

      COST = 16_384
      BLOCK_SIZE = 8
      PARALLELISM = 1
      LENGTH = 32

      def initialize
        @crypto = Node.require_module('node:crypto')
      end

      def digest(password)
        salt = `#{@crypto}.randomBytes(16)`
        hash = scrypt(password, salt, COST, BLOCK_SIZE, PARALLELISM, LENGTH)
        ['scrypt', COST, BLOCK_SIZE, PARALLELISM, `#{salt}.toString('base64')`, `#{hash}.toString('base64')`].join('$')
      end

      def matches?(password, digest)
        scheme, cost, block_size, parallelism, salt, hash = digest.to_s.split('$')
        return false unless scheme == 'scrypt' && hash

        expected = `Buffer.from(#{hash}, 'base64')`
        actual = scrypt(password, `Buffer.from(#{salt}, 'base64')`, cost.to_i, block_size.to_i, parallelism.to_i,
                        `#{expected}.length`)
        same_length = `#{expected}.length > 0 && #{expected}.length === #{actual}.length`
        same_length && `#{@crypto}.timingSafeEqual(#{expected}, #{actual})`
      rescue Exception # rubocop:disable Lint/RescueException -- a malformed digest throws in JS
        false
      end

      private

      def scrypt(password, salt, cost, block_size, parallelism, length)
        secret = password.to_s
        options = `{ N: #{cost}, r: #{block_size}, p: #{parallelism} }`
        `#{@crypto}.scryptSync(#{secret}, #{salt}, #{length}, #{options})`
      end
    end
  end
end
