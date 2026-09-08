# frozen_string_literal: true

module Chat
  module Payload
    def self.message(message)
      {
        id: message.id,
        conversation_id: message.conversation_id,
        sender_id: message.sender_id,
        body: message.body,
        created_at: message.created_at,
        read_at: message.read_at,
        attachment: attachment(message),
      }
    end

    def self.attachment(message)
      return nil unless message.file.attached?

      {
        filename: message.file.filename.to_s,
        content_type: message.file.content_type,
        byte_size: message.file.byte_size,
        url: "/conversations/#{message.conversation_id}/messages/#{message.id}/file",
      }
    end
  end
end
