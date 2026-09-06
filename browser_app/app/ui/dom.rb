# frozen_string_literal: true

# backtick_javascript: true

require 'native'

##
# The small set of raw DOM operations the UI needs. Kept separate so
# the rest of the app reads as plain Ruby rather than JavaScript
# embedded in backticks.
module Dom
  def self.set_html(selector, html)
    `document.querySelector(#{selector}).innerHTML = #{html}`
  end

  def self.value(selector)
    `document.querySelector(#{selector}).value`
  end

  def self.set_value(selector, value)
    `document.querySelector(#{selector}).value = #{value}`
  end

  def self.set_hidden(selector, hidden)
    `document.querySelector(#{selector}).hidden = #{hidden}`
  end

  def self.on(selector, event, &handler)
    `document.querySelector(#{selector}).addEventListener(#{event}, #{handler.to_n})`
  end

  # Listens on `container_selector` and only invokes the block when the
  # event actually originated from (or inside) an element matching
  # `child_selector` -- so newly rendered list/item rows are handled
  # without re-binding a listener on every render.
  def self.on_delegated(container_selector, event, child_selector, &block)
    handler = proc do |native_event|
      target = `#{native_event}.target.closest(#{child_selector})`
      matched = `#{target} !== null`
      block.call(target, native_event) if matched
    end
    `document.querySelector(#{container_selector}).addEventListener(#{event}, #{handler.to_n})`
  end

  def self.prevent_default(native_event)
    `#{native_event}.preventDefault()`
  end

  def self.data(element, key)
    `#{element}.dataset[#{key}]`
  end
end
