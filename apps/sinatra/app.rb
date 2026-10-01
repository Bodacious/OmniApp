# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'sinatra/base'
require 'tilt'
require 'slim'
require_relative '../../lib/omni/composition_root'

module Omni
  ##
  # The Sinatra app layer: HTTP in, use case calls on the domain's
  # Accounts and TodoService, a shared template out. Everything else
  # comes from the composition root.
  #
  # Who is signed in is kept in Sinatra's cookie session (signed,
  # HttpOnly, SameSite=Lax); the domain only ever sees a User.
  class SinatraApp < Sinatra::Base
    NAME = 'sinatra'

    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :host_authorization, { permitted_hosts: [] }
      set :sessions, key: 'omni.session', httponly: true, same_site: :lax
      set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
    end

    def self.compose(composition)
      set :composition, composition
      set :page, Tilt.new(composition.template_path, default_encoding: 'UTF-8')
      self
    end

    before do
      @user = accounts.find(session[:user_id])
    end

    # --- accounts

    get '/sign_in' do
      redirect '/', 303 if @user
      render_page('sign_in')
    end

    post '/sign_in' do
      sign_in(accounts.sign_in(email: string_param('email'), password: string_param('password')))
    rescue InvalidInput => e
      status 422
      render_page('sign_in', error: e.message, email: string_param('email'))
    end

    get '/sign_up' do
      redirect '/', 303 if @user
      render_page('sign_up')
    end

    post '/sign_up' do
      sign_in(accounts.sign_up(email: string_param('email'), password: string_param('password')))
    rescue InvalidInput => e
      status 422
      render_page('sign_up', error: e.message, email: string_param('email'))
    end

    post '/sign_out' do
      session.clear
      redirect '/sign_in', 303
    end

    # --- lists

    get '/' do
      require_user
      render_page('lists')
    end

    post '/lists' do
      require_user
      list = todo_service.create_list(@user, string_param('name'))
      redirect "/lists/#{list.id}", 303
    rescue InvalidInput => e
      status 422
      render_page('lists', error: e.message)
    end

    get '/lists/:list_id' do
      with_list { |list| render_page('list', list: list, tag: string_param('tag')) }
    end

    post '/lists/:list_id/delete' do
      require_user
      found { todo_service.delete_list(@user, params['list_id']) }
      redirect '/', 303
    end

    # --- todos on a list

    post '/lists/:list_id/todos' do
      change { |list| list.add(string_param('title'), string_param('tags')) }
    end

    post '/lists/:list_id/todos/:id/complete' do
      change { |list| list.complete(params['id']) }
    end

    post '/lists/:list_id/todos/:id/tags' do
      change { |list| list.tag(params['id'], string_param('tags')) }
    end

    post '/lists/:list_id/todos/:id/tags/:tag/delete' do
      change { |list| list.untag(params['id'], params['tag']) }
    end

    post '/lists/:list_id/todos/:id/delete' do
      change { |list| list.delete(params['id']) }
    end

    get '/health' do
      content_type :json
      JSON.generate(settings.composition.health)
    end

    private

    def accounts
      settings.composition.accounts
    end

    def todo_service
      settings.composition.todo_service
    end

    def sign_in(user)
      session.clear
      session[:user_id] = user.id
      redirect '/', 303
    end

    def require_user
      redirect '/sign_in', 303 unless @user
    end

    # Opens the signed-in user's list from the URL, or 404.
    def with_list
      require_user
      list = found { todo_service.list(@user, params['list_id']) }
      yield list
    end

    # Runs a use case on the open list, then back to it.
    def change
      with_list do |list|
        found { yield list }
        redirect "/lists/#{list.id}", 303
      rescue InvalidInput => e
        status 422
        render_page('list', list: list, error: e.message)
      end
    end

    def found
      yield
    rescue TodoService::NotFound => e
      halt 404, e.message
    end

    # A string parameter or nil (e.g. title[]=x arrives as an Array).
    # Whether it's valid is for the domain to judge.
    def string_param(name)
      value = params[name]
      value if value.is_a?(String)
    end

    def render_page(page, **)
      settings.page.render(settings.composition.view_context(page, user: @user, **))
    end
  end
end
