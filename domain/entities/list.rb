##
# A List is a single place to store a group of related tasks or reminders
class List
  attr_reader :name

  def initialize(**attributes)
    @name = attributes[:name]
  end
end