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

ActiveRecord::Schema.define(version: 2025_04_22_191510) do

  create_table "developer_matrices", force: :cascade do |t|
    t.integer "pr_id"
    t.string "github_id"
    t.integer "LOC"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "employees", force: :cascade do |t|
    t.string "github_id"
    t.string "name"
    t.float "dev_score", default: 0.0
    t.float "rev_score", default: 0.0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "merge_speed", default: 0.0
    t.float "churn_score", default: 0.0
    t.float "code_quality", default: 0.0
    t.float "review_coverage", default: 0.0
    t.float "response_time", default: 0.0
    t.float "closing_speed", default: 0.0
    t.float "engagement_score", default: 0.0
    t.float "response_to_feedback", default: 0.0
  end

  create_table "metric_ranges", force: :cascade do |t|
    t.string "metric_name"
    t.float "min"
    t.float "max"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "pr_id"
    t.datetime "pr_created_at"
    t.datetime "pr_closed_at"
    t.datetime "pr_merged_at"
    t.string "status"
    t.integer "LOC"
    t.integer "review_counts"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "pr_node_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "github_id"
    t.integer "review_id"
    t.datetime "rev_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "next_commit_at"
    t.string "review_node_id"
    t.integer "pr_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
