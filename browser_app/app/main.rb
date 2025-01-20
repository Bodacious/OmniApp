require 'opal'
require 'native'

require "promise"
require "models/list"
require  "repositories/list_repository"

ListRepository.new.all.map do |data|
  puts data
  puts List.new(data)
end

