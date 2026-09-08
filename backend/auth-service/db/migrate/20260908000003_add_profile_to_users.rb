class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :job_title
      t.string :pending_job_title
      t.string :address_line
      t.string :postal_code
      t.string :city
      t.string :country, default: "FR"
      t.integer :salary_cents
      t.string :contract_type
      t.date :hired_on
      t.string :iban
    end
  end
end
