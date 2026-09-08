class CreateLeaveBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_balances do |t|
      t.bigint :user_id, null: false
      t.decimal :days_remaining, precision: 5, scale: 1, null: false, default: 0

      t.timestamps
    end

    add_index :leave_balances, :user_id, unique: true
  end
end
