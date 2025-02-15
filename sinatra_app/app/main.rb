require "bundler"
Bundler.require(:default, :app)

$LOAD_PATH << File.dirname(__FILE__)

require_relative 'boot'
LOGGER_PATH = File.expand_path("../../../log/application.#{ENV['RACK_ENV']}.log", __FILE__)
APP_LOGGER = Logger.new(LOGGER_PATH)

class OmniApp < Sinatra::Base
  configure do
    set :environment, ENV['RACK_ENV'] || :development
    set :json_encoder, :to_json
    set :slim, layout: :layout
    set :server, %w[puma]
    enable :logging
  end

  configure :development do
    register Sinatra::Reloader
  end

  before do
    headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Headers"] = "accept, authorization, origin"
  end

  options "*" do
    response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS,POST"
    response.headers["Access-Control-Allow-Headers"] =
      "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  end

  get "/" do
    lists = list_repository.all
    slim :index, locals: { lists: lists }
  end

  post "/lists" do
    list = List.new(**params[:list])
    list_repo = list_repository
    if list_repo.save(list)
      redirect to("/lists/#{list.slug}")
      status 301
    else
      status 422
    end
  end

  get "/lists/:slug" do
    list = list_repository.find_by_slug(params[:slug])
    list_items = list_item_repository.all_for_list(list)
    slim :"lists/show", locals: { list: list, list_items: list_items }
  end

  delete "/lists/:slug" do
    list_repository.delete_by_slug(params[:slug])
    redirect to("/")
    status 301
  end

  post "/lists/:list_slug/items" do
    list_item = ListItem.new(**params[:list_item])
    if list_item_repository.save_list_item_to_list(list_slug: params[:list_slug], list_item: list_item)
      redirect to("/lists/#{params[:list_slug]}")
      status 301
    else
      status 422
    end
  end

  delete '/lists/:list_slug/items/:id' do
    if list_item_repository.delete_list_item(list_slug: params[:list_slug], id: params[:id])
      redirect to("/lists/#{params[:list_slug]}")
      status 301
    else
      status 404
    end
  end

  private

  def list_repository
    @list_repository ||= ListRepository.new(DB)
  end

  def list_item_repository
    @list_item_repository ||= ListItemRepository.new(DB)
  end
end
