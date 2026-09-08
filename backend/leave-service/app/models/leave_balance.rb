class LeaveBalance < ApplicationRecord
  # user_id references a user owned by auth-service (no cross-db FK).
  validates :user_id, presence: true, uniqueness: true
  validates :days_remaining, numericality: { greater_than_or_equal_to: 0 }
end
