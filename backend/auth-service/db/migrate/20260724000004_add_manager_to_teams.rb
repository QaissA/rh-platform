class AddManagerToTeams < ActiveRecord::Migration[8.1]
  def change
    # A team's designated manager (a user). Nullable: a team may be unmanaged,
    # and deleting the manager user nullifies the reference rather than the team.
    add_reference :teams, :manager, foreign_key: { to_table: :users }, null: true
  end
end
