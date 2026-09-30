# frozen_string_literal: true

require 'json'
require 'sinatra/base'
require 'tilt'
require 'slim'
require_relative '../../lib/omni/composition_root'

module Omni
  ##
  # The Sinatra app layer: HTTP in, use case calls on the domain's
  # TodoService, a shared template out. Everything else comes from the
  # composition root.
  class SinatraApp < Sinatra::Base
    NAME = 'sinatra'

    configure do
      set :show_exceptions, false
      set :raise_errors, false
      set :host_authorization, { permitted_hosts: [] }
    end

    def self.compose(composition)
      set :composition, composition
      set :page, Tilt.new(composition.template_path, default_encoding: 'UTF-8')
      self
    end

    get '/' do
      render_page(tag: string_param('tag'))
    end

    post '/todos' do
      todo_service.add(string_param('title'), string_param('tags'))
      redirect '/', 303
    rescue InvalidInput => e
      status 422
      render_page(error: e.message)
    end

    post '/todos/:id/complete' do
      change { todo_service.complete(params['id']) }
    end

    post '/todos/:id/tags' do
      change { todo_service.tag(params['id'], string_param('tags')) }
    end

    post '/todos/:id/tags/:tag/delete' do
      change { todo_service.untag(params['id'], params['tag']) }
    end

    post '/todos/:id/delete' do
      change { todo_service.delete(params['id']) }
    end

    get '/health' do
      content_type :json
      JSON.generate(settings.composition.health)
    end

    private

    def todo_service
      settings.composition.todo_service
    end

    # Runs a use case on an existing todo, then back to the list.
    def change
      yield
      redirect '/', 303
    rescue InvalidInput => e
      status 422
      render_page(error: e.message)
    rescue TodoService::NotFound
      halt 404, 'No such todo'
    end

    # A string parameter or nil (e.g. title[]=x arrives as an Array).
    # Whether it's valid is for the domain to judge.
    def string_param(name)
      value = params[name]
      value if value.is_a?(String)
    end

    def render_page(error: nil, tag: nil)
      settings.page.render(settings.composition.view_context(error: error, tag: tag))
    end
  end
end
