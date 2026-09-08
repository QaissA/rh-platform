class ConversationsController < ApplicationController
  before_action :require_authentication!
  before_action :set_conversation, only: [:read]

  def index
    conversations = Conversation.for_user(current_user.id).to_a
    ids = conversations.map(&:id)
    last_ids = Message.where(conversation_id: ids).group(:conversation_id).maximum(:id)
    lasts = Message.with_attached_file.where(id: last_ids.values).index_by(&:conversation_id)
    others = User.where(id: conversations.flat_map { |c| [c.user_a_id, c.user_b_id] } - [current_user.id])
                 .index_by(&:id)
    unread = Message.where(conversation_id: ids, read_at: nil)
                    .where.not(sender_id: current_user.id)
                    .group(:conversation_id)
                    .count

    ordered = conversations.sort_by { |c| [-(lasts[c.id]&.created_at&.to_i || 0), -c.id] }
    render json: ordered.map { |c|
      conversation_json(c, other: others[c.other_user_id(current_user.id)], last: lasts[c.id], unread: unread[c.id] || 0)
    }
  end

  def create
    other_id = params[:user_id].to_i
    if other_id == current_user.id
      return render json: { error: "Vous ne pouvez pas vous écrire à vous-même" }, status: :unprocessable_content
    end

    other = User.find_by(id: other_id)
    return render json: { error: "Utilisateur introuvable" }, status: :not_found unless other

    conversation = Conversation.find_or_create_pair!(current_user.id, other.id)
    status = conversation.previously_new_record? ? :created : :ok
    render json: conversation_json(conversation, other: other), status: status
  end

  def read
    @conversation.messages.where(read_at: nil).where.not(sender_id: current_user.id).update_all(read_at: Time.current)
    render json: conversation_json(@conversation, other: User.find(@conversation.other_user_id(current_user.id)))
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:id])
    return render json: { error: "Conversation introuvable" }, status: :not_found unless @conversation
    return if @conversation.participant?(current_user.id)

    render json: { error: "Accès refusé" }, status: :forbidden
  end

  def conversation_json(conversation, other:, last: nil, unread: nil)
    last ||= conversation.messages.order(:id).last
    unread = conversation.unread_count_for(current_user.id) if unread.nil?
    {
      id: conversation.id,
      other: member_json(other),
      last_message: last && message_json(last),
      unread_count: unread,
    }
  end

  def message_json(message)
    Chat::Payload.message(message)
  end
end
