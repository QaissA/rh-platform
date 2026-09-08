class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "api-gateway" }
  end
end
