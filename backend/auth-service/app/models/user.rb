class User < ApplicationRecord
  ROLES = %w[employee lead manager rh admin].freeze
  CONTRACT_TYPES = %w[cdi cdd stage alternance other].freeze
  MAX_SIGNATURE_BYTES = 200_000
  SIGNATURE_PNG = /\Adata:image\/png;base64,[A-Za-z0-9+\/=]+\z/

  has_secure_password

  belongs_to :team, optional: true

  # Org structure: an employee/lead is affected to one business unit and one
  # project within it; managers have a BU but no project.
  belongs_to :business_unit, optional: true
  belongs_to :project, optional: true

  # Teams this user is the designated manager of (usually zero or one).
  has_many :managed_teams, class_name: "Team", foreign_key: :manager_id, dependent: :nullify, inverse_of: :manager
  # Business units this user manages, and projects this user leads (approval chain).
  has_many :managed_business_units, class_name: "BusinessUnit", foreign_key: :manager_id, dependent: :nullify, inverse_of: :manager
  has_many :led_projects, class_name: "Project", foreign_key: :lead_id, dependent: :nullify, inverse_of: :lead

  enum :role, { employee: "employee", lead: "lead", manager: "manager", rh: "rh", admin: "admin" }, default: "employee"

  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :contract_type, inclusion: { in: CONTRACT_TYPES }, allow_nil: true
  validates :salary_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :iban, length: { maximum: 34 }, allow_blank: true
  validate :signature_png_format
  validate :project_within_business_unit

  before_validation :normalize_iban

  # A user is affected to a team; their project and business unit are derived
  # from it (team -> project -> business_unit). Managers have no team and set
  # their business_unit directly.
  before_validation :derive_org_from_team

  scope :admins, -> { where(role: "admin") }

  has_many :notifications, dependent: :delete_all

  # Teams this user can validate as a manager: teams they own, plus teams whose
  # project sits in a business unit they manage.
  def team_ids_in_scope
    ids = managed_teams.pluck(:id)
    bu_ids = managed_business_units.pluck(:id)
    if bu_ids.any?
      ids |= Team.joins(:project).where(projects: { business_unit_id: bu_ids }).pluck(:id)
    end
    ids
  end

  # True when this is the only remaining admin (used to block demotion/deletion).
  def last_admin?
    admin? && User.admins.where.not(id: id).none?
  end

  def signature_locked?
    ActiveModel::Type::Boolean.new.cast(signature_locked)
  end

  private

  def signature_png_format
    return if signature_png.blank?

    png = signature_png.to_s.delete(" \n")
    if png.bytesize > MAX_SIGNATURE_BYTES
      errors.add(:signature_png, "est trop volumineuse")
    elsif png !~ SIGNATURE_PNG
      errors.add(:signature_png, "doit être une image PNG")
    else
      self.signature_png = png
    end
  end

  def normalize_iban
    self.iban = iban.to_s.gsub(/\s+/, "").upcase.presence
  end

  # Keep project_id / business_unit_id in sync with the assigned team.
  def derive_org_from_team
    if team&.project
      self.project_id = team.project_id
      self.business_unit_id = team.project.business_unit_id
    elsif team_id.nil?
      # No team: drop the project; keep any directly-set BU (manager case).
      self.project_id = nil
    end
  end

  # A user's project must belong to the user's own business unit.
  def project_within_business_unit
    return if project.nil?

    if business_unit_id.blank?
      errors.add(:project, "nécessite une business unit")
    elsif project.business_unit_id != business_unit_id
      errors.add(:project, "doit appartenir à la business unit de l'employé·e")
    end
  end
end
