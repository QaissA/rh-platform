Rails.application.routes.draw do
  # Swagger UI + OpenAPI spec (aggregated docs for the whole platform).
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"

  mount ActionCable.server => "/cable"

  # Reverse-proxy every request to the matching downstream service.
  match "auth/*path",       to: "proxy#forward", defaults: { prefix: "auth" },       via: :all
  match "leave/*path",      to: "proxy#forward", defaults: { prefix: "leave" },      via: :all
  match "admin-docs/*path", to: "proxy#forward", defaults: { prefix: "admin-docs" }, via: :all
end
