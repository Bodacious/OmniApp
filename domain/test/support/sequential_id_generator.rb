# frozen_string_literal: true

require 'ports/id_generator'

##
# A test double for the id generator port: predictable ids.
class SequentialIdGenerator
  include Ports::IdGenerator

  def initialize
    @last = 0
  end

  def next_id
    @last += 1
    "todo-#{@last}"
  end
end
