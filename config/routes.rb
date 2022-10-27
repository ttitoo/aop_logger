# frozen_string_literal: true

MiraclePlus::Logger::Engine.routes.draw do
  get '/', to: 'logging#index', as: :logging_index
  get :targets, to: 'logging#targets'
  get :candidates, to: 'logging#candidates'
  resources :entries, controller: :api, only: %i[index show create update destroy]
end
