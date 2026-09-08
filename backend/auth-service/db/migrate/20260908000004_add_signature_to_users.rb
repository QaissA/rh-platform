class AddSignatureToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.text :signature_png
      t.boolean :signature_locked, null: false, default: false
    end
  end
end
