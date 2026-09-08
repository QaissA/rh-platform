class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :user_a, null: false, foreign_key: { to_table: :users }
      t.references :user_b, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :conversations, [:user_a_id, :user_b_id], unique: true
    add_check_constraint :conversations, "user_a_id < user_b_id", name: "conversations_user_order"

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :messages, [:conversation_id, :created_at]
  end
end
