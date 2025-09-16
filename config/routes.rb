Rails.application.routes.draw do

  devise_for :users, controllers: { :sessions => "users/sessions"}
  devise_scope :user do
    root :to => 'devise/sessions#new'
  end

  #================================= Reports
  namespace :reports do
    get "dashboard" => "main#dashboard", as: :dashboard
  end
  get "up" => "rails/health#show", as: :rails_health_check
  
end
