# frozen_string_literal: true

Rails.application.routes.draw do
  omni = Rails.configuration.x.omni

  root 'lists#index'

  get '/sign_in', to: 'accounts#sign_in_form'
  post '/sign_in', to: 'accounts#sign_in'
  get '/sign_up', to: 'accounts#sign_up_form'
  post '/sign_up', to: 'accounts#sign_up'
  post '/sign_out', to: 'accounts#sign_out'

  post '/lists', to: 'lists#create'
  get '/lists/:list_id', to: 'lists#show'
  post '/lists/:list_id/delete', to: 'lists#destroy'

  post '/lists/:list_id/todos', to: 'todos#create'
  post '/lists/:list_id/todos/:id/complete', to: 'todos#complete'
  post '/lists/:list_id/todos/:id/tags', to: 'todos#tag'
  post '/lists/:list_id/todos/:id/tags/:tag/delete', to: 'todos#untag'
  post '/lists/:list_id/todos/:id/delete', to: 'todos#destroy'

  get '/health', to: 'health#show'

  # Test-only plumbing from the composition root: a Rack endpoint, so it
  # sits outside the controllers (and their CSRF check).
  post '/__test__/reset', to: omni.test_reset_endpoint if omni.test_mode?
end
