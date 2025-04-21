Rails.application.routes.draw do
  get 'dashboard/index'
  devise_for :users
  root to: "dashboard#index"
  get "dashboard/show/:id", to: "dashboard#show", as: "dashboard_show"
  get "dashboard/raw", to: "dashboard#raw", as: "dashboard_raw"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
