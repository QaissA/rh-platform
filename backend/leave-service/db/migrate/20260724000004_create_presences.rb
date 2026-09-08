class CreatePresences < ActiveRecord::Migration[8.1]
  def change
    create_table :presences do |t|
      t.bigint :user_id, null: false
      # Requester's team (denormalized from the X-User-Team-Id header at creation)
      # so a team schedule can be scoped without reaching into auth-service.
      t.bigint :team_id
      t.date :date, null: false
      # Work location for the day: "on_site" or "remote". (Holidays are derived
      # from approved leave requests, not stored here.)
      t.string :status, null: false, default: "on_site"

      t.timestamps
    end

    # One declaration per user per day (upserted when re-declared).
    add_index :presences, [:user_id, :date], unique: true
    add_index :presences, [:team_id, :date]
  end
end
