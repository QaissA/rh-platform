class AddWorkflowToLeaveRequests < ActiveRecord::Migration[8.1]
  def change
    # Requester's team (denormalized from the X-User-Team-Id header at creation)
    # so a manager can scope/approve requests without reaching into auth-service.
    add_column :leave_requests, :team_id, :bigint

    # Approval audit trail.
    add_column :leave_requests, :decided_by, :bigint
    add_column :leave_requests, :decided_at, :datetime
    add_column :leave_requests, :decision_comment, :string

    add_index :leave_requests, :team_id
  end
end
