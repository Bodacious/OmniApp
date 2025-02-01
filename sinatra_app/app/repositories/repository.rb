class Repository
  attr_reader :database
  attr_accessor :table_name

  require "forwardable"
  extend Forwardable

  def self.table_name
    @table_name ||= name.gsub("Repository", "").gsub(/([A-Z])/, '_\1').downcase.sub(
      /^_/, ""
    ) + "s"
  end

  def_delegators :data_source, :insert, :all

  def initialize(database_connection)
    @database = database_connection
    @table_name = self.class.table_name
  end

  def data_source
    database[table_name.to_sym]
  end
end
