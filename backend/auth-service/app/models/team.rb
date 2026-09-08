class Team < ApplicationRecord
  has_many :users, dependent: :nullify

  # A team is the roster of exactly one project (1:1).
  belongs_to :project, optional: true

  # Legacy: teams used to carry their own manager (flat model). Retained so the
  # old data/endpoints keep working; the approval chain now uses BU/project.
  belongs_to :manager, class_name: "User", optional: true

  validates :name, presence: true
  validates :project_id, uniqueness: true, allow_nil: true
  validate :manager_can_manage

  private

  def manager_can_manage
    return if manager.nil?
    return if manager.manager? || manager.admin?

    errors.add(:manager, "doit avoir le rôle manager ou admin")
  end
end
