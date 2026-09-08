# frozen_string_literal: true

class Message < ApplicationRecord
  MAX_BODY = 4_000
  MAX_FILE_BYTES = 5.megabytes
  ALLOWED_TYPES = %w[application/pdf image/png image/jpeg image/webp].freeze

  belongs_to :conversation
  belongs_to :sender, class_name: "User"
  has_one_attached :file

  validates :body, length: { maximum: MAX_BODY }, allow_blank: true
  validate :sender_is_participant
  validate :body_or_file
  validate :file_constraints

  def attached?
    file.attached?
  end

  private

  def sender_is_participant
    return if conversation&.participant?(sender_id)

    errors.add(:sender, "n’est pas participant")
  end

  def body_or_file
    return if body.to_s.strip.present? || file.attached?

    errors.add(:base, "Écrivez un message ou joignez un fichier")
  end

  def file_constraints
    return unless file.attached?

    if file.byte_size > MAX_FILE_BYTES
      errors.add(:file, "est trop volumineux (5 Mo max)")
      file.purge
    elsif ALLOWED_TYPES.exclude?(file.content_type)
      errors.add(:file, "doit être un PDF ou une image")
      file.purge
    end
  end
end
