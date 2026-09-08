class CreateDocumentRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :document_requests do |t|
      t.bigint :user_id, null: false
      t.string :doc_type, null: false
      t.string :status, null: false, default: "pending"
      t.text :note

      t.timestamps
    end

    add_index :document_requests, :user_id
  end
end
