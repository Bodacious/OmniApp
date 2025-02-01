class List
  attr_accessor :id
  attr_accessor :name
  attr_accessor :items

  def initialize(**attributes)
    @id = attributes[:id]
    @name = attributes[:name]
    @items = Array(attributes[:items])
  end

  def persisted?
    !id.nil?
  end
end
