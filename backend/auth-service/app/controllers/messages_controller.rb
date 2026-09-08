class MessagesController < ApplicationController
  before_action :require_authentication!
  before_action :set_conversation
  before_action :set_message, only: [:file]

  def index
    messages = @conversation.messages.with_attached_file.order(id: :desc).limit(100).to_a.reverse
    render json: messages.map { |m| Chat::Payload.message(m) }
  end

  def create
    message = @conversation.messages.new(sender: current_user, body: params[:body].to_s.strip)
    message.file.attach(params[:file]) if params[:file].present?
    if message.save
      Chat::Broadcast.message(message)
      render json: Chat::Payload.message(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_content
    end
  end

  def file
    return head :not_found unless @message.file.attached?

    send_data @message.file.download,
              filename: @message.file.filename.to_s,
              type: @message.file.content_type,
              disposition: params[:download].present? ? "attachment" : "inline"
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])
    return render json: { error: "Conversation introuvable" }, status: :not_found unless @conversation
    return if @conversation.participant?(current_user.id)

    render json: { error: "Accès refusé" }, status: :forbidden
  end

  def set_message
    return if performed?

    @message = @conversation.messages.find_by(id: params[:id])
    render json: { error: "Message introuvable" }, status: :not_found unless @message
  end
end
