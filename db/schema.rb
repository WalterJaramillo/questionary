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

ActiveRecord::Schema[8.1].define(version: 2026_06_22_003311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_correct", default: false, null: false
    t.bigint "question_id", null: false
    t.string "selected_option", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "question_id"], name: "index_answers_on_attempt_id_and_question_id", unique: true
    t.index ["attempt_id"], name: "index_answers_on_attempt_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "score", default: 0, null: false
    t.datetime "started_at", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "student_id", null: false
    t.integer "total_questions", default: 30, null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_attempts_on_student_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "correct_answer", null: false
    t.datetime "created_at", null: false
    t.integer "item", null: false
    t.text "option_a", null: false
    t.text "option_b", null: false
    t.text "option_c", null: false
    t.text "option_d", null: false
    t.text "question_text", null: false
    t.string "seccion"
    t.string "tema"
    t.datetime "updated_at", null: false
    t.index ["item"], name: "index_questions_on_item", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "cedula", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "zona", default: "", null: false
    t.index ["cedula"], name: "index_students_on_cedula", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "admin", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "attempts"
  add_foreign_key "answers", "questions"
  add_foreign_key "attempts", "students"
end
