class ApplicationController < ActionController::API
  # The gateway validates the JWT and forwards the authenticated identity.
  def current_user_id
    request.headers["X-User-Id"].presence
  end

  def current_user_role
    request.headers["X-User-Role"].presence
  end

  def admin?
    current_user_role == "admin"
  end

  def rh?
    current_user_role == "rh"
  end

  def hr_officer?
    rh? || admin?
  end

  def require_user!
    return if current_user_id

    render json: { error: "Missing authenticated user" }, status: :unauthorized
  end

  def require_hr!
    return render json: { error: "Authentification requise" }, status: :unauthorized unless current_user_id
    return if hr_officer?

    render json: { error: "Accès réservé à la RH" }, status: :forbidden
  end
end
