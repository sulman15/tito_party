require 'sidekiq/web'

Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'
  get 'sync', to: 'home#sync'
  get 'headings/index'
  # Sidekiq Web Interface
  mount Sidekiq::Web => '/sidekiq'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  get 'scrapes', to: 'scrapes#index'
  resources :headings, only: [:index]
  get 'subheading_text', to: 'headings#subheading_text'
end
