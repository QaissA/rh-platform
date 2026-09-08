class Notification < ApplicationRecord
  KINDS = %w[
    document_ready
    leave_manager_approved
    leave_hr_approved
    job_title_approved
    job_title_rejected
    signature_unlocked
  ].freeze

  belongs_to :user

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :title, presence: true

  scope :for_user, ->(user_id) { where(user_id: user_id).order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def unread?
    read_at.nil?
  end
end
