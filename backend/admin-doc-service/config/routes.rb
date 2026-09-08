Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  resources :requests, only: [:index, :show, :create, :update], controller: "document_requests" do
    collection do
      get :inbox
    end
  end
end
