# frozen_string_literal: true

Rails.application.routes.draw do
  omni = Rails.configuration.x.omni

  root 'todos#index'
  post '/todos', to: 'todos#create'
  post '/todos/:id/complete', to: 'todos#complete'
  post '/todos/:id/delete', to: 'todos#destroy'
  get '/health', to: 'todos#health'

  # Test-only plumbing from the composition root: a Rack endpoint, so it
  # sits outside the controllers (and their CSRF check).
  post '/__test__/reset', to: omni.test_reset_endpoint if omni.test_mode?
end
