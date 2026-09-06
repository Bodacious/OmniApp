# frozen_string_literal: true

# backtick_javascript: true

require 'json'

##
# Reads and writes a single named collection (a Hash of id => record)
# as JSON in the browser's window.localStorage, so data survives page
# reloads without needing a server -- the browser's answer to the
# other apps' SQLite backend.
module LocalStorageCollection
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
