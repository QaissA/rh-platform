class ProfilesController < ApplicationController
  before_action :require_authentication!

  def show
    render json: profile_json(current_user)
  end

  def update
    current_user.assign_attributes(address_params)
    if params.key?(:pending_job_title)
      title = params[:pending_job_title].to_s.strip.presence
      current_user.pending_job_title = title
    end
    return unless apply_signature!

    if current_user.save
      render json: profile_json(current_user)
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def address_params
    params.permit(:address_line, :postal_code, :city, :country)
  end

  def apply_signature!
    return true unless params.key?(:signature_png)

    if current_user.signature_png.present? && current_user.signature_locked?
      render json: { error: "La signature est verrouillée. Demandez à la RH de l’ouvrir à nouveau." },
             status: :forbidden
      return false
    end

    png = params[:signature_png].to_s.strip
    if png.blank?
      render json: { error: "La signature est vide" }, status: :unprocessable_content
      return false
    end

    current_user.signature_png = png
    current_user.signature_locked = true
    true
  end
end
