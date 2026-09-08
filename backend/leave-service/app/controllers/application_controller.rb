class ApplicationController < ActionController::API
  # The gateway validates the JWT and forwards the authenticated identity via
  # headers (X-User-Id, X-User-Role, X-User-Team-Id, X-Managed-Team-Ids).
  def current_user_id
    request.headers["X-User-Id"].presence
  end

  def current_user_role
    request.headers["X-User-Role"].presence
  end

  def current_user_team_id
    request.headers["X-User-Team-Id"].presence
  end

  # Ids of the teams the caller is the designated manager of.
  def managed_team_ids
    request.headers["X-Managed-Team-Ids"].to_s.split(",").map(&:to_i)
  end

  def admin?
    current_user_role == "admin"
  end

  def manager?
    current_user_role == "manager"
  end

  def rh?
    current_user_role == "rh"
  end

  def require_user!
    return if current_user_id

    render json: { error: "Missing authenticated user" }, status: :unauthorized
  end
end
