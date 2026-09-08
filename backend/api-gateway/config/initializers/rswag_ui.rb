Rswag::Ui.configure do |c|
  # Swagger UI (served at /api-docs) points at the aggregated spec below.
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "RH Platform API V1"
end
