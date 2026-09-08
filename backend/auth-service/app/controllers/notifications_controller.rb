class NotificationsController < ApplicationController
  before_action :require_authentication!

  # GET /notifications
  def index
    notes = Notification.for_user(current_user.id).limit(40)
    render json: notes.map { |n| notification_json(n) }
  end

  # PATCH /notifications/:id/read
  def read
    note = Notification.for_user(current_user.id).find_by(id: params[:id])
    return render json: { error: "Notification introuvable" }, status: :not_found unless note

    note.update!(read_at: Time.current) if note.unread?
    render json: notification_json(note)
  end

  private

  def notification_json(n)
    {
      id: n.id,
      kind: n.kind,
      title: n.title,
      body: n.body,
      link: n.link,
      read: !n.unread?,
      created_at: n.created_at,
    }
  end
end
