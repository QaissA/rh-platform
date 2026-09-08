class AddOrgToUsers < ActiveRecord::Migration[8.1]
  def change
    # An employee/lead is affected to one business unit and one project within it.
    # (Nullable: managers have a BU but no project; unassigned users have neither.)
    add_reference :users, :business_unit, foreign_key: true, null: true
    add_reference :users, :project, foreign_key: true, null: true
  end
end
