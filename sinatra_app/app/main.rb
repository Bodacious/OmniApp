require 'bundler'
Bundler.require

$LOAD_PATH << File.expand_path('../../../core_app', __FILE__)

require_relative 'repositories/list_repository'
require_relative 'repositories/list_item_repository'

set :server, %w[puma]

get '/' do
  slim :index
end

post '/lists' do
  list_data = params[:list]
  list = ListRepository.new.create(**list_data)
  if list.persisted?
    headers({ "Location" => "https://localhost:3000/lists/#{list.id}" })
    status 301
  else
    status 422
  end
end

get '/lists/:id' do
  ListRepository.new.find(params[:id])
end

post '/lists/:list_id/items' do
  list_item_attributes = params['item'].merge(list_id: params['list_id'])
  item = ListItemRepository.new.create(**list_item_attributes)
  if item.persisted?
    headers({ "Location" => "https://localhost:3000/lists/#{item.list_id}" })
    status 301
  else
    status 422
  end
end