class InternalNotificationsController < ApplicationController
  skip_before_action :require_authentication!, raise: false

  # POST /internal/notifications  -> called by leave-service / admin-doc-service
  def create
    return render json: { error: "Unauthorized" }, status: :unauthorized unless valid_internal_token?

    user = User.find_by(id: params[:user_id])
    return render json: { error: "Utilisateur introuvable" }, status: :not_found unless user

    note = Notification.new(
      user: user,
      kind: params[:kind],
      title: params[:title],
      body: params[:body],
      link: params[:link],
    )

    if note.save
      deliver_email(user, note)
      render json: { id: note.id }, status: :created
    else
      render json: { errors: note.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def valid_internal_token?
    expected = ENV.fetch("INTERNAL_TOKEN", "dev-internal-token")
    provided = request.headers["X-Internal-Token"].to_s
    return false if expected.blank? || provided.blank? || provided.bytesize != expected.bytesize

    ActiveSupport::SecurityUtils.secure_compare(provided, expected)
  end

  def deliver_email(user, note)
    Rails.logger.info("[notification-email] to=#{user.email} kind=#{note.kind} subject=#{note.title}")
    NotificationMailer.alert(user, note).deliver_now
  rescue StandardError => e
    Rails.logger.warn("[notification-email] failed: #{e.message}")
  end
end
