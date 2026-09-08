class CreateBusinessUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :business_units do |t|
      t.string :name, null: false
      # The BU's manager (a user). Nullable so a BU can be created before staffing.
      t.references :manager, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
