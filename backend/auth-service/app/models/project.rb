class Project < ApplicationRecord
  belongs_to :business_unit
  # A project has exactly one team (its roster).
  has_one :team, dependent: :nullify
  has_many :members, class_name: "User", foreign_key: :project_id, dependent: :nullify, inverse_of: :project

  # The project's lead, who forms the first stage of the leave-approval chain.
  belongs_to :lead, class_name: "User", optional: true

  validates :name, presence: true
  validate :lead_can_lead

  private

  # Only a lead (or an admin) may lead a project.
  def lead_can_lead
    return if lead.nil?
    return if lead.lead? || lead.admin?

    errors.add(:lead, "doit avoir le rôle chef·fe de projet")
  end
end
