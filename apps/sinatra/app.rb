# frozen_string_literal: true

require 'json'
require 'sinatra/base'
require 'tilt'
require 'slim'
require_relative '../../lib/omni/composition_root'

module Omni
  ##
  # The Sinatra app layer: HTTP in, use case calls on the domain's
  # TodoList, a shared template out. Everything else comes from the
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
      set :page, Tilt.new(composition.template_path)
      self
    end

    get '/' do
      render_page
    end

    post '/todos' do
      todo_list.add(params['title'])
      redirect '/', 303
    rescue Todo::Invalid => e
      status 422
      render_page(error: e.message)
    end

    post '/todos/:id/complete' do
      todo_list.complete(params['id'])
      redirect '/', 303
    rescue TodoList::NotFound
      halt 404, 'No such todo'
    end

    post '/todos/:id/delete' do
      todo_list.delete(params['id'])
      redirect '/', 303
    rescue TodoList::NotFound
      halt 404, 'No such todo'
    end

    get '/health' do
      content_type :json
      JSON.generate(settings.composition.health)
    end

    private

    def todo_list
      settings.composition.todo_list
    end

    def render_page(error: nil)
      settings.page.render(settings.composition.view_context(error: error))
    end
  end
end
