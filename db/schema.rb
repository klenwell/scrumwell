# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_07_221630) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "scrum_backlogs", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.string "trello_list_id"
    t.string "trello_pos"
    t.string "name"
    t.datetime "last_pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_scrum_backlogs_on_scrum_board_id"
    t.index ["trello_list_id"], name: "index_scrum_backlogs_on_trello_list_id"
  end

  create_table "scrum_boards", force: :cascade do |t|
    t.string "trello_board_id"
    t.string "trello_url"
    t.string "name"
    t.datetime "last_board_activity_at"
    t.datetime "last_pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scrum_sprints", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.string "trello_list_id"
    t.integer "trello_pos"
    t.string "name"
    t.date "started_on"
    t.date "ended_on"
    t.datetime "last_pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_scrum_sprints_on_scrum_board_id"
  end

  create_table "user_stories", force: :cascade do |t|
    t.bigint "queue_id"
    t.string "trello_card_id"
    t.string "trello_short_url"
    t.text "trello_name"
    t.text "title"
    t.text "description"
    t.integer "points"
    t.datetime "completed_at"
    t.datetime "last_activity_at"
    t.datetime "last_pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "trello_pos"
    t.string "queue_type"
    t.index ["queue_type", "queue_id"], name: "index_user_stories_on_queue_type_and_queue_id"
  end

  create_table "wish_heaps", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.string "trello_list_id"
    t.integer "trello_pos"
    t.string "name"
    t.datetime "last_pulled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_wish_heaps_on_scrum_board_id"
  end

  add_foreign_key "scrum_backlogs", "scrum_boards"
  add_foreign_key "scrum_sprints", "scrum_boards"
  add_foreign_key "wish_heaps", "scrum_boards"
end
