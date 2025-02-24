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

    # Has this item been marked as done?
    # @return [Boolean]
    def done? = @done

    # Should this item be added to the list when refreshed?
    # @return [Boolean]
    def repeatable? = @repeatable

    # Toggle the value of +done?+
    # @return [Boolean]
    def toggle_done
      self.done = !done?
    end

    # Toggle the value of +repeatable?+
    # @return [Boolean]
    def toggle_repeatable
      self.repeatable = !repeatable?
    end

    def undo
      toggle_done if done?
      done?
    end
    def refresh
      if repeatable?
        new_instance.undo
        new_instance
      else
        self
      end
    end
  end
end
