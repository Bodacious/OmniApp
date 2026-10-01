# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require_relative '../../domain/ports/password_hasher'

module Adapters
  module Passwords
    ##
    # The password hasher port over scrypt, from OpenSSL in Ruby's
    # standard library. Digests look like
    #
    #   scrypt$16384$8$1$<salt, base64>$<hash, base64>
    #
    # which the Node app's adapter (node:crypto's scryptSync) reads and
    # writes too, so an account made on a Ruby stack can sign in on the
    # Node one against the same database.
    class ScryptPasswordHasher
      include Ports::PasswordHasher

      COST = 16_384
      BLOCK_SIZE = 8
      PARALLELISM = 1
      LENGTH = 32

      def digest(password)
        salt = SecureRandom.random_bytes(16)
        hash = scrypt(password, salt, COST, BLOCK_SIZE, PARALLELISM, LENGTH)
        ['scrypt', COST, BLOCK_SIZE, PARALLELISM, base64(salt), base64(hash)].join('$')
      end

      def matches?(password, digest)
        scheme, cost, block_size, parallelism, salt, hash = digest.to_s.split('$')
        return false unless scheme == 'scrypt' && hash

        expected = unbase64(hash)
        actual = scrypt(password, unbase64(salt), Integer(cost), Integer(block_size), Integer(parallelism),
                        expected.bytesize)
        OpenSSL.fixed_length_secure_compare(actual, expected)
      rescue ArgumentError, OpenSSL::KDF::KDFError
        false
      end

      private

      def scrypt(password, salt, cost, block_size, parallelism, length)
        OpenSSL::KDF.scrypt(password.to_s, salt: salt, N: cost, r: block_size, p: parallelism, length: length)
      end

      def base64(bytes)
        [bytes].pack('m0')
      end

      def unbase64(text)
        text.unpack1('m0')
      end
    end
  end
end
