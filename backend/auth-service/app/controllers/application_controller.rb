class ApplicationController < ActionController::API
  # The gateway validates the JWT and forwards the authenticated user id.
  # We resolve the user from the database so authorization always reflects the
  # current role (not a stale role baked into an old token).
  def current_user
    @current_user ||= User.find_by(id: request.headers["X-User-Id"])
  end

  def require_authentication!
    return if current_user

    render json: { error: "Authentification requise" }, status: :unauthorized
  end

  def require_admin!
    return if current_user&.admin?

    if current_user
      render json: { error: "Accès réservé aux administrateurs" }, status: :forbidden
    else
      render json: { error: "Authentification requise" }, status: :unauthorized
    end
  end

  def require_admin_or_rh!
    return if current_user&.admin? || current_user&.rh?

    if current_user
      render json: { error: "Accès réservé aux administrateurs et à la RH" }, status: :forbidden
    else
      render json: { error: "Authentification requise" }, status: :unauthorized
    end
  end

  # Public representation of a user (never exposes password_digest or pay data).
  def user_json(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      team_id: user.team_id,
      business_unit_id: user.business_unit_id,
      project_id: user.project_id,
      must_change_password: user.must_change_password,
      job_title: user.job_title,
      pending_job_title: user.pending_job_title,
    }
  end

  def profile_json(user)
    user_json(user).merge(
      pending_job_title: user.pending_job_title,
      address_line: user.address_line,
      postal_code: user.postal_code,
      city: user.city,
      country: user.country,
      signature_png: user.signature_png,
      signature_locked: user.signature_locked?,
    )
  end

  def dossier_json(user)
    profile_json(user).merge(
      salary_cents: user.salary_cents,
      contract_type: user.contract_type,
      hired_on: user.hired_on,
      iban: user.iban,
    )
  end

  def notify_user!(user, kind:, title:, body:, link:)
    Notifications::Deliver.call(user, kind:, title:, body:, link:)
  end

  # Compact user representation for embedding in team/BU/project payloads.
  def member_json(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      job_title: user.job_title,
    }
  end
end
