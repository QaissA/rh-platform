class SessionsController < ApplicationController
  before_action :require_authentication!, only: [:me]

  # POST /login  -> authenticate and issue a JWT
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode({
        user_id: user.id,
        role: user.role,
        team_id: user.team_id,
        managed_team_ids: user.team_ids_in_scope,
        business_unit_id: user.business_unit_id,
        project_id: user.project_id,
        led_project_ids: user.led_projects.pluck(:id),
        managed_bu_ids: user.managed_business_units.pluck(:id),
      })
      render json: { token: token, user: user_json(user) }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # GET /me  -> the current authenticated user (from the forwarded token)
  def me
    render json: user_json(current_user)
  end
end
