Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  get 'home/index'
  root 'home#index'
  match '/results',   to: 'home#results',   via: 'get'
  match '/send_sms',   to: 'home#send_sms',   via: 'get'
  match '/receive_sms',   to: 'home#receive_sms',   via: 'post'
  match '/test',   to: 'home#test',   via: 'post'
  match '/test',   to: 'home#test',   via: 'get'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
