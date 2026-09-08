class LeaveRequest < ApplicationRecord
  # user_id references a user owned by auth-service (no cross-db FK).
  enum :status, {
    pending: "pending",
    pending_hr: "pending_hr",
    approved: "approved",
    rejected: "rejected",
  }, default: "pending"

  def awaiting?
    pending? || pending_hr?
  end

  validates :user_id, :start_date, :end_date, presence: true
  validate :end_after_start

  scope :for_teams, ->(team_ids) { where(team_id: team_ids) }
  # Requests whose [start_date, end_date] span intersects the given window.
  scope :overlapping, ->(from, to) { where("start_date <= ? AND end_date >= ?", to, from) }

  # Number of working days (Mon–Fri) covered by the request, inclusive.
  # Weekends are excluded; public holidays are out of scope.
  def working_days
    return 0 if start_date.blank? || end_date.blank?

    (start_date..end_date).count { |day| (1..5).cover?(day.wday) }
  end

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be on or after start_date") if end_date < start_date
  end
end
