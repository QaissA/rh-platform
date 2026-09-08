class DocumentRequest < ApplicationRecord
  # user_id references a user owned by auth-service (no cross-db FK).
  DOC_TYPES = %w[work_certificate salary_certificate leave_attestation other].freeze
  FIELD_KEYS = %w[
    employee_name job_title start_date company purpose
    period net_salary leave_start leave_end days leave_type
    title body issued_date signer
  ].freeze

  enum :status, {
    pending: "pending",
    processing: "processing",
    ready: "ready",
    rejected: "rejected",
    cancelled: "cancelled",
  }, default: "pending"

  validates :user_id, presence: true
  validates :doc_type, presence: true, inclusion: { in: DOC_TYPES }

  def open?
    pending? || processing?
  end

  def closed?
    rejected? || cancelled?
  end
end
