class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "admin-doc-service" }
  end
end
