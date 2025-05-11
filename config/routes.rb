Rails.application.routes.draw do
  get 'headings/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  get 'scrapes', to: 'scrapes#index'
  resources :headings, only: [:index]
end
