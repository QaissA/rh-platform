class CreateLeaveRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :leave_requests do |t|
      t.bigint :user_id, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: "pending"
      t.string :reason

      t.timestamps
    end

    add_index :leave_requests, :user_id
  end
end
