Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]
  resources :bodyweight_entries, except: :show
  resources :lifts, except: :show

  get "dashboard", to: "dashboard#show", as: :dashboard

  namespace :admin do
    root "lifts#index"
    resources :lifts, only: %i[ index destroy ] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :users, only: %i[ index show destroy ]
  end

  root "pages#home"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
