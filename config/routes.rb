Rails.application.routes.draw do

  devise_for :users, controllers: { :sessions => "users/sessions"}
  devise_scope :user do
    root :to => 'devise/sessions#new'
  end

  #================================= Reports
  namespace :reports do
    get "dashboard" => "main#dashboard", as: :dashboard
    resources :surveillance, only: [:index] do
      collection do
         get :line_list
         get :simple_activity_line_list
      end
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
  #nfs_picture_path
  get '/nfs_picture', to: 'ajax#nfs_picture'
  get 'ajax/populate_tehsil', to: 'ajax#populate_tehsil'
  get 'ajax/populate_uc', to: 'ajax#populate_uc'
  get '/ajax/populate_sub_departments', to: 'ajax#populate_sub_departments'
end
