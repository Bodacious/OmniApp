# frozen_string_literal: true

# backtick_javascript: true

require 'omni_node/node'

module OmniNode
  ##
  # Remembers who is signed in, in an HMAC-signed cookie: the user's id
  # and a SHA-256 HMAC of it under a secret only this process knows.
  # HttpOnly, so scripts can't read it; SameSite=Lax, so other sites
  # can't make the browser send it with their form posts.
  #
  # Like the Rails and Sinatra sessions, this is app-layer plumbing: the
  # domain only ever sees the User it names.
  class SessionCookie
    NAME = 'omni_session'
    ATTRIBUTES = 'Path=/; HttpOnly; SameSite=Lax'

    # Without a +secret+ (SESSION_SECRET), a random one: sessions then
    # last as long as the process, as in the Sinatra app.
    def initialize(secret = nil)
      @crypto = Node.require_module('node:crypto')
      @secret = secret.nil? || secret.empty? ? `#{@crypto}.randomBytes(32).toString('hex')` : secret
    end

    # The user id in the request's Cookie header, if its signature holds.
    def user_id(cookie_header)
      value = cookies(cookie_header)[NAME]
      return nil unless value

      user_id, signature = value.split('.', 2)
      user_id if signature && valid?(user_id, signature)
    end

    # A Set-Cookie header value signing in +user_id+.
    def sign_in(user_id)
      "#{NAME}=#{user_id}.#{sign(user_id)}; #{ATTRIBUTES}"
    end

    # A Set-Cookie header value that removes the session.
    def sign_out
      "#{NAME}=; #{ATTRIBUTES}; Max-Age=0"
    end

    private

    def sign(value)
      `#{@crypto}.createHmac('sha256', #{@secret}).update(#{value}).digest('hex')`
    end

    def valid?(value, signature)
      expected = `Buffer.from(#{sign(value)})`
      actual = `Buffer.from(#{signature})`
      `#{expected}.length === #{actual}.length && #{@crypto}.timingSafeEqual(#{expected}, #{actual})`
    end

    def cookies(header)
      header.to_s.split(/;\s*/).each_with_object({}) do |pair, cookies|
        name, value = pair.split('=', 2)
        cookies[name] = value if name && value
      end
    end
  end
end
