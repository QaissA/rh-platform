class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint :user_id, null: false
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.string :link
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, [:user_id, :read_at]
  end
end
