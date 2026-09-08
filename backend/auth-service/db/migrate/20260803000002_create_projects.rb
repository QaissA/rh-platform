class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.references :business_unit, foreign_key: true, null: false
      # The project's lead (a user). Nullable until one is designated.
      t.references :lead, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
