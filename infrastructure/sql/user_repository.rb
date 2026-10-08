# frozen_string_literal: true

require 'securerandom'
require 'sequel'
require_relative '../../domain/model/user_repository'

module Infrastructure
  module Sql
    ##
    # The domain's UserRepository, stored in a Sequel database's users
    # table.
    class UserRepository
      include ::UserRepository

      # @param database [Sequel::Database]
      def initialize(database)
        @users = database[:users]
      end

      def next_identity
        SecureRandom.uuid
      end

      def find(id)
        build(@users.where(id: id.to_s).first)
      end

      def find_by_email(email)
        build(@users.where(email: email.to_s).first)
      end

      def save(user)
        @users.insert_conflict(target: :id,
                               update: { email: ::Sequel[:excluded][:email],
                                         password_digest: ::Sequel[:excluded][:password_digest] })
              .insert(id: user.id, email: user.email, password_digest: user.password_digest)
        user
      end

      # Deletes every user: the test-only reset, not part of the repository.
      def clear
        @users.delete
      end

      private

      def build(row)
        row && User.new(id: row[:id], email: row[:email], password_digest: row[:password_digest])
      end
    end
  end
end
