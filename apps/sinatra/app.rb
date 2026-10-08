# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'sinatra/base'
require 'tilt'
require 'slim'
require_relative '../../lib/omni/composition_root'

module Omni
  ##
  # The Sinatra app layer: HTTP in, a shared template out. Each route
  # loads an aggregate from its repository, tells it what to do and
  # saves it. The rules are the domain's; everything else comes from
  # the composition root.
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
      @user = users.find(session[:user_id])
    end

    # --- accounts

    get '/sign_in' do
      redirect '/', 303 if @user
      render_page('sign_in')
    end

    post '/sign_in' do
      sign_in(users.account_for(string_param('email')).authenticate(string_param('password'), password_hasher))
    rescue InvalidInput => e
      status 422
      render_page('sign_in', error: e.message, email: string_param('email'))
    end

    get '/sign_up' do
      redirect '/', 303 if @user
      render_page('sign_up')
    end

    post '/sign_up' do
      sign_in(users.add(User.register(id: users.next_identity, email: string_param('email'),
                                      password: string_param('password'), hasher: password_hasher)))
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
      list = lists.save(List.new(id: lists.next_identity, owner_id: @user.id, name: string_param('name')))
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
      found { lists.remove(lists.fetch(params['list_id'], owner: @user)) }
      redirect '/', 303
    end

    # --- todos on a list

    post '/lists/:list_id/todos' do
      change { |list| list.add(id: lists.next_identity, title: string_param('title'), tags: string_param('tags')) }
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
      change { |list| list.remove(params['id']) }
    end

    get '/health' do
      content_type :json
      JSON.generate(settings.composition.health)
    end

    private

    def users
      settings.composition.users
    end

    def lists
      settings.composition.lists
    end

    def password_hasher
      settings.composition.password_hasher
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
      list = found { lists.fetch(params['list_id'], owner: @user) }
      yield list
    end

    # Changes the open list, saves it, then goes back to it.
    def change
      with_list do |list|
        found { yield list }
        lists.save(list)
        redirect "/lists/#{list.id}", 303
      rescue InvalidInput => e
        status 422
        render_page('list', list: list, error: e.message)
      end
    end

    def found
      yield
    rescue NotFound => e
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
