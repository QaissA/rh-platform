# frozen_string_literal: true

module Notifications
  class Deliver
    def self.call(user, kind:, title:, body:, link:)
      note = Notification.create!(user: user, kind: kind, title: title, body: body, link: link)
      Rails.logger.info("[notification-email] to=#{user.email} kind=#{note.kind} subject=#{note.title}")
      NotificationMailer.alert(user, note).deliver_now
    rescue StandardError => e
      Rails.logger.warn("[notification-email] failed: #{e.message}")
    end
  end
end
