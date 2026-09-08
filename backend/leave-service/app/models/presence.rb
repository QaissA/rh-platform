class Presence < ApplicationRecord
  # user_id / team_id reference records owned by auth-service (no cross-db FK).
  # A day a user is on holiday is represented by an approved LeaveRequest, not a
  # Presence row; Presence only records the on-site/remote work location.
  STATUSES = %w[on_site remote].freeze
  enum :status, { on_site: "on_site", remote: "remote" }, default: "on_site"

  validates :user_id, :date, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :for_team, ->(team_id) { where(team_id: team_id) }
  scope :in_range, ->(start_date, end_date) { where(date: start_date..end_date) }
end
