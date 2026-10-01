# frozen_string_literal: true

require 'sequel'
require_relative '../../../domain/model/user'
require_relative '../../../domain/ports/user_repository'

module Adapters
  module Persistence
    module Sql
      ##
      # The user repository port over a Sequel database.
      class UserRepository
        include Ports::UserRepository

        def initialize(database)
          @users = database[:users]
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

        # Not part of the port: the composition root's test-only reset.
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
end
