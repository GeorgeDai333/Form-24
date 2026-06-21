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

ActiveRecord::Schema[8.1].define(version: 2026_06_21_120000) do
  create_table "form24_games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "deck"
    t.integer "draws", default: 0, null: false
    t.text "hand"
    t.integer "penalty", default: 0, null: false
    t.integer "score", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_form24_games_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "card_1"
    t.integer "card_2"
    t.integer "card_3"
    t.integer "card_4"
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_games_on_user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "match_id", null: false
    t.integer "score"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["match_id"], name: "index_participations_on_match_id"
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "total_score"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "form24_games", "users"
  add_foreign_key "games", "users"
  add_foreign_key "participations", "matches"
  add_foreign_key "participations", "users"
end
