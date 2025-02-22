# frozen_string_literal: true

class List
  ##
  # A List::Item represents one item on a list that can be marked as "done" when complete.
  class Item
    attr_reader :summary

    attr_writer :done
    private :done=

    attr_writer :repeatable
    private :repeatable=
    def initialize(**attributes)
      @summary = attributes[:summary]
      @done = attributes[:done]
      @repeatable = attributes.fetch(:repeatable, false)
    end

    def done? = @done

    def repeatable? = @repeatable

    def toggle_done
      self.done = !done?
    end

    def toggle_repeatable
      self.repeatable = !repeatable?
    end
  end
end
