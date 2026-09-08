class AddFieldsToDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :document_requests, :fields, :jsonb, null: false, default: {}
    add_column :document_requests, :issued_by, :bigint
    add_column :document_requests, :issued_at, :datetime
    add_column :document_requests, :decision_comment, :string
  end
end
