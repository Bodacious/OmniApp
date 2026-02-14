# frozen_string_literal: true

Rails.application.routes.draw do
  resources :lists, param: :slug do
    resources :items, only: %i[create destroy], controller: 'lists/items'
  end
  root 'lists#index'
end
