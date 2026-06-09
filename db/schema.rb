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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_000000) do
  create_table "attendance_answers", force: :cascade do |t|
    t.integer "attendance_field_id", null: false
    t.integer "attendance_response_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["attendance_field_id"], name: "index_attendance_answers_on_attendance_field_id"
    t.index ["attendance_response_id", "attendance_field_id"], name: "idx_on_attendance_response_id_attendance_field_id_fe725e575c", unique: true
    t.index ["attendance_response_id"], name: "index_attendance_answers_on_attendance_response_id"
  end

  create_table "attendance_fields", force: :cascade do |t|
    t.integer "attendance_list_id", null: false
    t.datetime "created_at", null: false
    t.string "field_type", default: "text", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.boolean "required", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_list_id", "position"], name: "index_attendance_fields_on_attendance_list_id_and_position"
    t.index ["attendance_list_id"], name: "index_attendance_fields_on_attendance_list_id"
  end

  create_table "attendance_lists", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "public_token", null: false
    t.datetime "starts_at"
    t.string "time_zone", default: "America/Sao_Paulo", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["public_token"], name: "index_attendance_lists_on_public_token", unique: true
    t.index ["user_id"], name: "index_attendance_lists_on_user_id"
  end

  create_table "attendance_responses", force: :cascade do |t|
    t.integer "attendance_list_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["attendance_list_id", "submitted_at"], name: "idx_on_attendance_list_id_submitted_at_910736a30a"
    t.index ["attendance_list_id"], name: "index_attendance_responses_on_attendance_list_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.datetime "inactivity_terms_accepted_at", null: false
    t.datetime "last_login_at", null: false
    t.datetime "remember_created_at"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "attendance_answers", "attendance_fields"
  add_foreign_key "attendance_answers", "attendance_responses"
  add_foreign_key "attendance_fields", "attendance_lists"
  add_foreign_key "attendance_lists", "users"
  add_foreign_key "attendance_responses", "attendance_lists"
end
