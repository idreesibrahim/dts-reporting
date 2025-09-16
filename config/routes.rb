Rails.application.routes.draw do

  devise_for :users, controllers: { :sessions => "users/sessions"}
  devise_scope :user do
    root :to => 'devise/sessions#new'
  end

  #================================= Reports
  namespace :reports do
    get "dormancy" => "main#dormancy_report", as: :dormancy
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
