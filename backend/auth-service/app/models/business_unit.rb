class BusinessUnit < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :users, dependent: :nullify

  # The BU's manager, who forms the second stage of the leave-approval chain.
  belongs_to :manager, class_name: "User", optional: true

  validates :name, presence: true
  validate :manager_can_manage

  private

  # Only a manager or an admin may run a business unit.
  def manager_can_manage
    return if manager.nil?
    return if manager.manager? || manager.admin?

    errors.add(:manager, "doit avoir le rôle manager ou admin")
  end
end
