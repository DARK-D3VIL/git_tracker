Rails.application.routes.draw do
  get 'employee/index'
  get 'dashboard/index'
  devise_for :users
  root to: "dashboard#index"
  get "employee/:id", to: "employee#index", as: "employee"
  get "dashboard/raw", to: "dashboard#raw", as: "dashboard_raw"
  match "*unmatched", to: "application#not_found", via: :all

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
