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

  resources :categories do
    resources :subcategories
  end

  resources :subcategories do
    resources :products
  end

  resources :products

  get 'scrape_categories', to: 'home#scrape_categories'
  get 'scrape_products', to: 'home#scrape_products'
  get 'export_csv', to: 'home#export_csv'
  get 'export_human_resources_csv', to: 'home#export_human_resources_csv'
  get 'scrape_human_resources', to: 'home#scrape_human_resources', as: 'scrape_human_resources'
end
