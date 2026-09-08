Rswag::Api.configure do |c|
  # Folder that holds the OpenAPI spec files served by rswag-api.
  c.openapi_root = Rails.root.join("swagger").to_s
end
