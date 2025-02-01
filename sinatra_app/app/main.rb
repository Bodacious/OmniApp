require 'bundler'
Bundler.require

$LOAD_PATH << File.expand_path('../../../core_app', __FILE__)

require 'config/database'

class App < Sinatra::Base
  DATABASE = Database.new
  DATABASE.build_schema

  configure do
    set :json_encoder, :to_json
    set :erb, layout: :layout
    set :slim, layout: :layout
    set :server, %w[puma]
    enable :logging
  end

  before do
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin'
  end

  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS,POST'
    response.headers['Access-Control-Allow-Headers'] =
      'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  end

  get '/' do
    slim :index
  end

  post '/lists' do
    list_data = params[:list]
    list = ListRepository.new(DATABASE).create(**list_data)
    if list.persisted?
      redirect to("/lists/#{list.id}")
      status 301
    else
      status 422
    end
  end

  get '/lists/:id' do
    list = ListRepository.new(DATABASE).find(params[:id])
    slim :"lists/show", locals: { list: list }
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
end
