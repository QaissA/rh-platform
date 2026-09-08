class AddPasswordChangeToUsers < ActiveRecord::Migration[8.1]
  def change
    # Accounts created by an admin start with a generated password and must
    # set their own on first login.
    add_column :users, :must_change_password, :boolean, null: false, default: false
    add_column :users, :password_changed_at, :datetime
  end
end
