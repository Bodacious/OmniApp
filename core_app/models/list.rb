class List
  attr_accessor :id, :name
  def initialize(**attributes)
    @attributes = attributes
  end

  def persisted?
    !id.nil?
  end
end
