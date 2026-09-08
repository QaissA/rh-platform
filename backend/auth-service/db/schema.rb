# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_08_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "business_units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "manager_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_business_units_on_manager_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.index ["user_a_id", "user_b_id"], name: "index_conversations_on_user_a_id_and_user_b_id", unique: true
    t.index ["user_a_id"], name: "index_conversations_on_user_a_id"
    t.index ["user_b_id"], name: "index_conversations_on_user_b_id"
    t.check_constraint "user_a_id < user_b_id", name: "conversations_user_order"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "link"
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "business_unit_id", null: false
    t.datetime "created_at", null: false
    t.bigint "lead_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["business_unit_id"], name: "index_projects_on_business_unit_id"
    t.index ["lead_id"], name: "index_projects_on_lead_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "manager_id"
    t.string "name", null: false
    t.bigint "project_id"
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_teams_on_manager_id"
    t.index ["project_id"], name: "index_teams_on_project_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "address_line"
    t.bigint "business_unit_id"
    t.string "city"
    t.string "contract_type"
    t.string "country", default: "FR"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.date "hired_on"
    t.string "iban"
    t.string "job_title"
    t.string "last_name"
    t.boolean "must_change_password", default: false, null: false
    t.datetime "password_changed_at"
    t.string "password_digest", null: false
    t.string "pending_job_title"
    t.string "postal_code"
    t.bigint "project_id"
    t.string "role", default: "employee", null: false
    t.integer "salary_cents"
    t.boolean "signature_locked", default: false, null: false
    t.text "signature_png"
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["business_unit_id"], name: "index_users_on_business_unit_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["project_id"], name: "index_users_on_project_id"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "business_units", "users", column: "manager_id"
  add_foreign_key "conversations", "users", column: "user_a_id"
  add_foreign_key "conversations", "users", column: "user_b_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "projects", "business_units"
  add_foreign_key "projects", "users", column: "lead_id"
  add_foreign_key "teams", "projects"
  add_foreign_key "teams", "users", column: "manager_id"
  add_foreign_key "users", "business_units"
  add_foreign_key "users", "projects"
  add_foreign_key "users", "teams"
end
