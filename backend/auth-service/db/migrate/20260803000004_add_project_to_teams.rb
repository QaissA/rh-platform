class AddProjectToTeams < ActiveRecord::Migration[8.1]
  def change
    # A team is the roster of exactly one project (1:1), so the FK is unique.
    add_reference :teams, :project, foreign_key: true, null: true, index: { unique: true }
  end
end
