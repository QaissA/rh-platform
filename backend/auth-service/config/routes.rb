Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  post "login" => "sessions#create"
  get "me" => "sessions#me"
  match "password" => "passwords#update", via: [:patch, :put]
  get "profile" => "profiles#show"
  match "profile" => "profiles#update", via: [:patch, :put]

  get "teams/mine" => "teams#mine"
  resources :teams, only: [:index, :show, :create, :update, :destroy]

  # Org structure: business units and their projects (admin only)
  resources :business_units, only: [:index, :show, :create, :update, :destroy], path: "business-units"
  resources :projects, only: [:index, :show, :create, :update, :destroy]

  # Admin-only user & role management
  resources :users, only: [:index, :show, :create, :update, :destroy] do
    member do
      post :reset_password, path: "reset-password"
      post :accept_job_title, path: "job-title/accept"
      post :reject_job_title, path: "job-title/reject"
      post :unlock_signature, path: "signature/unlock"
    end
  end

  get "notifications" => "notifications#index"
  patch "notifications/:id/read" => "notifications#read"
  post "internal/notifications" => "internal_notifications#create"
end
