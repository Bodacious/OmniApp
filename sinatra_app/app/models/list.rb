class List
  using CoreExtensions::Hash::SymbolizeKeys
  using CoreExtensions::String::Transformations

  attr_reader :attributes

  def initialize(**attributes)
    @attributes = attributes.symbolize_keys
    self.attributes[:slug] ||= self.attributes[:name].to_s.dasherize
  end

  def persisted?
    !id.nil?
  end

  def id
    attributes[:id]
  end

  def id=(value)
    attributes[:id] = value
  end

  def name
    attributes[:name]
  end

  def name=(value)
    attributes[:name] = value
  end

  def slug
    attributes[:slug]
  end
end
