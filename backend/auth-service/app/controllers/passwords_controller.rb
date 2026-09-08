class PasswordsController < ApplicationController
  before_action :require_authentication!

  MIN_LENGTH = 8

  # PATCH /password  -> the current user sets a new password.
  # Used for the forced change on first login (and voluntary changes later).
  def update
    unless current_user.authenticate(params[:current_password].to_s)
      return render json: { error: "Mot de passe actuel incorrect" }, status: :unauthorized
    end

    new_password = params[:new_password].to_s

    if new_password.length < MIN_LENGTH
      return render json: { error: "Le nouveau mot de passe doit contenir au moins #{MIN_LENGTH} caractères" },
                    status: :unprocessable_content
    end

    if current_user.authenticate(new_password)
      return render json: { error: "Le nouveau mot de passe doit être différent de l'ancien" },
                    status: :unprocessable_content
    end

    current_user.password = new_password
    current_user.must_change_password = false
    current_user.password_changed_at = Time.current

    if current_user.save
      render json: user_json(current_user)
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
