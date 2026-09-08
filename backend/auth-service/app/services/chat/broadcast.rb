# frozen_string_literal: true

module Chat
  class Broadcast
    def self.message(message)
      payload = {
        type: "message",
        conversation_id: message.conversation_id,
        message: Chat::Payload.message(message),
      }
      [message.conversation.user_a_id, message.conversation.user_b_id].each do |uid|
        ActionCable.server.broadcast("chat:user:#{uid}", payload)
      end
    rescue StandardError => e
      Rails.logger.warn("[chat-broadcast] #{e.class}: #{e.message}")
    end
  end
end
