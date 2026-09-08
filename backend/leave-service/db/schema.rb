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

ActiveRecord::Schema[8.1].define(version: 2026_07_24_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "leave_balances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "days_remaining", precision: 5, scale: 1, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_leave_balances_on_user_id", unique: true
  end

  create_table "leave_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.bigint "decided_by"
    t.string "decision_comment"
    t.date "end_date", null: false
    t.string "reason"
    t.date "start_date", null: false
    t.string "status", default: "pending", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["team_id"], name: "index_leave_requests_on_team_id"
    t.index ["user_id"], name: "index_leave_requests_on_user_id"
  end

  create_table "presences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "status", default: "on_site", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["team_id", "date"], name: "index_presences_on_team_id_and_date"
    t.index ["user_id", "date"], name: "index_presences_on_user_id_and_date", unique: true
  end
end
