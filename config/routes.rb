# frozen_string_literal: true

MiraclePlus::Logger::Engine.routes.draw do
  get :comp, to: 'logging#comp', as: :logging_component
  get :targets, to: 'logging#targets'
  get :candidates, to: 'logging#candidates'
  resources :entries, controller: :api, only: %i[index show create update destroy]
end
