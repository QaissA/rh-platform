Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  get "balance" => "leave_balances#show"

  # Team "emploi du temps": daily on-site/remote/holiday state of each member.
  get "schedule" => "schedule#index"
  # Self-service work-location declarations for the current user.
  resources :presences, only: [:create]

  resources :requests, only: [:index, :create], controller: "leave_requests" do
    collection do
      get :team
    end
    member do
      patch :approve
      patch :reject
    end
  end
end
