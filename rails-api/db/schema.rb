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

ActiveRecord::Schema[7.1].define(version: 2025_07_18_000016) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "professional_id", null: false
    t.bigint "client_id", null: false
    t.bigint "student_id"
    t.datetime "scheduled_at", null: false
    t.integer "duration_minutes", default: 60, null: false
    t.string "state", default: "draft", null: false
    t.text "notes"
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.decimal "price", precision: 10, scale: 2
    t.boolean "uses_credits", default: false
    t.integer "credits_used"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.datetime "executed_at"
    t.text "professional_notes"
    t.boolean "uses_credit", default: false
    t.index ["client_id", "scheduled_at"], name: "index_appointments_on_client_id_and_scheduled_at"
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["organization_id", "scheduled_at"], name: "index_appointments_on_organization_id_and_scheduled_at"
    t.index ["organization_id", "state"], name: "index_appointments_on_organization_id_and_state"
    t.index ["organization_id"], name: "index_appointments_on_organization_id"
    t.index ["professional_id", "scheduled_at"], name: "index_appointments_on_professional_id_and_scheduled_at"
    t.index ["professional_id"], name: "index_appointments_on_professional_id"
    t.index ["scheduled_at"], name: "index_appointments_on_scheduled_at"
    t.index ["state"], name: "index_appointments_on_state"
    t.index ["student_id"], name: "index_appointments_on_student_id"
  end

  create_table "availability_rules", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.bigint "organization_id", null: false
    t.integer "day_of_week", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "idx_org_availability"
    t.index ["organization_id"], name: "index_availability_rules_on_organization_id"
    t.index ["professional_id", "day_of_week", "active"], name: "idx_availability_lookup"
    t.index ["professional_id"], name: "index_availability_rules_on_professional_id"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "chk_valid_day_of_week"
  end

  create_table "credit_balances", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.integer "balance", default: 0, null: false
    t.integer "lifetime_purchased", default: 0, null: false
    t.integer "lifetime_used", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "balance"], name: "idx_org_balance_lookup"
    t.index ["organization_id", "user_id"], name: "idx_unique_user_credit_balance", unique: true
    t.index ["organization_id"], name: "index_credit_balances_on_organization_id"
    t.index ["user_id"], name: "index_credit_balances_on_user_id"
  end

  create_table "credit_transactions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.bigint "credit_balance_id", null: false
    t.bigint "appointment_id"
    t.integer "amount", null: false
    t.string "transaction_type", null: false
    t.string "status", default: "pending", null: false
    t.jsonb "metadata", default: {}
    t.string "payment_method"
    t.string "payment_reference"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_credit_transactions_on_appointment_id"
    t.index ["credit_balance_id"], name: "index_credit_transactions_on_credit_balance_id"
    t.index ["organization_id", "status"], name: "idx_credit_trans_org_status"
    t.index ["organization_id", "user_id", "created_at"], name: "idx_credit_trans_org_user_date"
    t.index ["organization_id"], name: "index_credit_transactions_on_organization_id"
    t.index ["payment_reference"], name: "idx_credit_trans_payment_ref"
    t.index ["user_id"], name: "index_credit_transactions_on_user_id"
    t.check_constraint "transaction_type::text = ANY (ARRAY['purchase'::character varying, 'cancellation_refund'::character varying, 'appointment_debit'::character varying, 'admin_adjustment'::character varying]::text[])", name: "chk_valid_transaction_type"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id", "user_id", "post_id"], name: "index_likes_on_org_user_post", unique: true
    t.index ["organization_id"], name: "index_likes_on_organization_id"
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.boolean "active", default: true, null: false
    t.jsonb "settings", default: {}
    t.string "phone"
    t.string "email"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.integer "post_id"
    t.string "hash_id"
    t.string "source"
    t.text "metadata"
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.text "content"
    t.boolean "published"
    t.index ["organization_id", "created_at"], name: "index_posts_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_posts_on_organization_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "professionals", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.string "title"
    t.string "specialization"
    t.text "bio"
    t.string "license_number"
    t.date "license_expiry"
    t.jsonb "availability", default: {}
    t.integer "session_duration_minutes", default: 60
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.boolean "active", default: true
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "weekly_schedule", default: {}
    t.jsonb "blocked_dates", default: []
    t.integer "buffer_minutes", default: 15
    t.boolean "accepts_new_clients", default: true
    t.integer "session_price_cents"
    t.string "currency", default: "ARS"
    t.index ["active"], name: "index_professionals_on_active"
    t.index ["organization_id", "specialization"], name: "index_professionals_on_organization_id_and_specialization"
    t.index ["organization_id", "user_id"], name: "index_professionals_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_professionals_on_organization_id"
    t.index ["specialization"], name: "index_professionals_on_specialization"
    t.index ["user_id"], name: "index_professionals_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "key", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_roles_on_active"
    t.index ["organization_id", "key"], name: "index_roles_on_organization_and_key", unique: true
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "students", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "parent_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "date_of_birth"
    t.string "gender"
    t.string "grade_level"
    t.text "medical_notes"
    t.text "educational_notes"
    t.jsonb "emergency_contacts", default: []
    t.boolean "active", default: true
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_students_on_active"
    t.index ["first_name", "last_name"], name: "index_students_on_first_name_and_last_name"
    t.index ["organization_id", "parent_id"], name: "index_students_on_organization_id_and_parent_id"
    t.index ["organization_id"], name: "index_students_on_organization_id"
    t.index ["parent_id"], name: "index_students_on_parent_id"
  end

  create_table "time_slots", force: :cascade do |t|
    t.bigint "professional_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "appointment_id"
    t.date "date", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.boolean "available", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_time_slots_on_appointment_id"
    t.index ["organization_id", "date"], name: "idx_org_date_slots"
    t.index ["organization_id"], name: "index_time_slots_on_organization_id"
    t.index ["professional_id", "date", "available"], name: "idx_available_slots"
    t.index ["professional_id", "date", "start_time"], name: "idx_unique_time_slot", unique: true
    t.index ["professional_id"], name: "index_time_slots_on_professional_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.bigint "organization_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "assigned_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_user_roles_on_active"
    t.index ["assigned_at"], name: "index_user_roles_on_assigned_at"
    t.index ["organization_id", "role_id"], name: "index_user_roles_on_org_role"
    t.index ["organization_id", "user_id"], name: "index_user_roles_on_org_user"
    t.index ["organization_id"], name: "index_user_roles_on_organization_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id", "organization_id"], name: "index_user_roles_on_user_role_org", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "image"
    t.string "username"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 3, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "jti", null: false
    t.string "provider"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id", "role"], name: "index_users_on_organization_id_and_role"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "appointments", "organizations"
  add_foreign_key "appointments", "students"
  add_foreign_key "appointments", "users", column: "client_id"
  add_foreign_key "appointments", "users", column: "professional_id"
  add_foreign_key "availability_rules", "organizations"
  add_foreign_key "availability_rules", "professionals"
  add_foreign_key "credit_balances", "organizations"
  add_foreign_key "credit_balances", "users"
  add_foreign_key "credit_transactions", "appointments"
  add_foreign_key "credit_transactions", "credit_balances"
  add_foreign_key "credit_transactions", "organizations"
  add_foreign_key "credit_transactions", "users"
  add_foreign_key "likes", "organizations"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "posts", "organizations"
  add_foreign_key "posts", "users"
  add_foreign_key "professionals", "organizations"
  add_foreign_key "professionals", "users"
  add_foreign_key "roles", "organizations"
  add_foreign_key "students", "organizations"
  add_foreign_key "students", "users", column: "parent_id"
  add_foreign_key "time_slots", "appointments"
  add_foreign_key "time_slots", "organizations"
  add_foreign_key "time_slots", "professionals"
  add_foreign_key "user_roles", "organizations"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "organizations"
end
