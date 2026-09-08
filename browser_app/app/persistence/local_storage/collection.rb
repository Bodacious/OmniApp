# frozen_string_literal: true

# backtick_javascript: true

require 'json'

module Persistence
  module LocalStorage
    ##
    # Reads and writes a single named collection (a Hash of id =>
    # record) as JSON in the browser's window.localStorage. The only
    # place in the app that touches a browser API directly.
    module Collection
      def self.read(key)
        json = `window.localStorage.getItem(#{key})`
        present = `#{json} !== null`
        return {} unless present

        JSON.parse(json)
      end

      def self.write(key, records)
        `window.localStorage.setItem(#{key}, #{JSON.generate(records)})`
      end
    end
  end
end
