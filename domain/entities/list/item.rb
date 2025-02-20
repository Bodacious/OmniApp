# frozen_string_literal: true

class List
  class Item
    attr_reader :summary
    attr_writer :done, :summary


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
