class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "leave-service" }
  end
end
