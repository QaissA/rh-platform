class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "auth-service" }
  end
end
