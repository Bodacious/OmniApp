# frozen_string_literal: true

require 'js'

module OmniWasm
  module UI
    ##
    # The handful of DOM operations the UI needs, through the js gem.
    # The rest of the UI reads as Ruby and never touches JS directly.
    module Dom
      module_function

      def document
        JS.global[:document]
      end

      def find(selector)
        element = document.call(:querySelector, selector)
        element == JS::Null ? nil : element
      end

      def region(name)
        find("[data-region='#{name}']")
      end

      def fill(name, html)
        region(name)[:innerHTML] = html
      end

      # One listener on the document for each event type; handlers look
      # at what was actually clicked or submitted.
      def on(event_type, &handler)
        document.call(:addEventListener, event_type) { |event| handler.call(event) }
      end

      # The nearest element to the event's target matching +selector+.
      def closest(event, selector)
        element = event[:target].call(:closest, selector)
        element == JS::Null ? nil : element
      end

      def data(element, key)
        element[:dataset][key].to_s
      end

      # Restarts a CSS animation on every element matching +selector+.
      def pulse(selector, css_class)
        list = document.call(:querySelectorAll, selector)
        list[:length].to_i.times do |index|
          element = list.call(:item, index)
          element[:classList].call(:remove, css_class)
          element[:offsetWidth] # forces a reflow so the animation restarts
          element[:classList].call(:add, css_class)
        end
      end

      def query_param(name)
        value = JS.eval("return new URLSearchParams(location.search).get(#{name.to_s.inspect})")
        value == JS::Null ? nil : value.to_s
      end

      def replace_query(name, value)
        JS.eval("const u = new URL(location.href); u.searchParams.set(#{name.inspect}, #{value.inspect}); " \
                'history.replaceState(null, "", u)')
      end
    end
  end
end
