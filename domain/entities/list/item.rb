# frozen_string_literal: true

class List
  ##
  # A List::Item represents one item on a list that can be marked as "done" when complete.
  class Item
    attr_reader :summary

    attr_writer :done
    private :done=
    def initialize(**attributes)
      @summary = attributes[:summary]
      @done = attributes[:done]
    end

    def done? = @done

    def toggle_done
      self.done = !done?
    end
  end
end
