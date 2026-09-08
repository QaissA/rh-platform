class Conversation < ApplicationRecord
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"
  has_many :messages, dependent: :destroy

  validates :user_a_id, uniqueness: { scope: :user_b_id }
  validate :ordered_pair

  def self.pair_ids(id1, id2)
    [id1.to_i, id2.to_i].minmax
  end

  def self.for_user(user_id)
    where("user_a_id = :id OR user_b_id = :id", id: user_id.to_i)
  end

  def self.find_or_create_pair!(user_id, other_id)
    a, b = pair_ids(user_id, other_id)
    find_or_create_by!(user_a_id: a, user_b_id: b)
  end

  def participant?(user_id)
    user_id.to_i == user_a_id || user_id.to_i == user_b_id
  end

  def other_user_id(user_id)
    user_id.to_i == user_a_id ? user_b_id : user_a_id
  end

  def unread_count_for(user_id)
    messages.where(read_at: nil).where.not(sender_id: user_id).count
  end

  private

  def ordered_pair
    return if user_a_id.blank? || user_b_id.blank?

    errors.add(:base, "user_a_id must be less than user_b_id") if user_a_id >= user_b_id
  end
end
