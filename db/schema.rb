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

ActiveRecord::Schema[8.1].define(version: 2026_09_20_140000) do
  create_table "bodyweight_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "kilograms", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "recorded_at"], name: "index_bodyweight_entries_on_user_id_and_recorded_at"
    t.index ["user_id"], name: "index_bodyweight_entries_on_user_id"
    t.check_constraint "kilograms > 20 AND kilograms < 400", name: "bodyweight_entries_plausible"
  end

  create_table "lifts", force: :cascade do |t|
    t.decimal "bodyweight_kg"
    t.datetime "created_at", null: false
    t.string "exercise", null: false
    t.date "lifted_at", null: false
    t.integer "reps", null: false
    t.decimal "score", precision: 10, scale: 2
    t.string "status", default: "approved", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.decimal "weight_lifted", null: false
    t.index ["status"], name: "index_lifts_on_status"
    t.index ["user_id", "exercise", "score"], name: "index_lifts_on_user_id_and_exercise_and_score"
    t.index ["user_id"], name: "index_lifts_on_user_id"
    t.check_constraint "bodyweight_kg IS NULL OR (bodyweight_kg > 20 AND bodyweight_kg < 400)", name: "lifts_bodyweight_plausible"
    t.check_constraint "reps > 0", name: "lifts_reps_positive"
    t.check_constraint "status IN ('approved', 'pending', 'rejected')", name: "lifts_status_known"
    t.check_constraint "weight_lifted >= 0", name: "lifts_weight_not_negative"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.json "featured_badges", default: [], null: false
    t.string "password_digest", null: false
    t.boolean "public_profile", default: false, null: false
    t.integer "sex", null: false
    t.string "time_zone", default: "Etc/UTC", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.integer "weight_unit", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
    t.check_constraint "sex IN (0, 1)", name: "users_sex_known"
    t.check_constraint "weight_unit IN (0, 1)", name: "users_weight_unit_known"
  end

  add_foreign_key "bodyweight_entries", "users"
  add_foreign_key "lifts", "users"
  add_foreign_key "sessions", "users"
end
