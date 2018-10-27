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

ActiveRecord::Schema.define(version: 2018_10_27_200621) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "scrum_boards", force: :cascade do |t|
    t.string "trello_board_id"
    t.string "trello_url"
    t.string "name"
    t.datetime "last_imported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scrum_events", force: :cascade do |t|
    t.string "eventable_type"
    t.bigint "eventable_id"
    t.bigint "scrum_board_id"
    t.string "action"
    t.string "trello_id"
    t.string "trello_type"
    t.string "trello_object"
    t.json "trello_data"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["eventable_type", "eventable_id"], name: "index_scrum_events_on_eventable_type_and_eventable_id"
    t.index ["scrum_board_id"], name: "index_scrum_events_on_scrum_board_id"
  end

  create_table "scrum_queues", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.string "trello_list_id"
    t.integer "trello_pos"
    t.string "name"
    t.date "started_on"
    t.date "ended_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_scrum_queues_on_scrum_board_id"
  end

  create_table "scrum_stories", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.bigint "scrum_queue_id"
    t.string "trello_card_id"
    t.text "title"
    t.integer "points"
    t.json "trello_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_scrum_stories_on_scrum_board_id"
    t.index ["scrum_queue_id"], name: "index_scrum_stories_on_scrum_queue_id"
  end

  create_table "wip_logs", force: :cascade do |t|
    t.bigint "scrum_board_id"
    t.bigint "scrum_event_id"
    t.integer "points_completed"
    t.json "wip_changes"
    t.json "wip"
    t.json "daily_velocity"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_board_id"], name: "index_wip_logs_on_scrum_board_id"
    t.index ["scrum_event_id"], name: "index_wip_logs_on_scrum_event_id"
  end

  add_foreign_key "scrum_events", "scrum_boards"
  add_foreign_key "scrum_queues", "scrum_boards"
  add_foreign_key "scrum_stories", "scrum_boards"
  add_foreign_key "scrum_stories", "scrum_queues"
  add_foreign_key "wip_logs", "scrum_boards"
  add_foreign_key "wip_logs", "scrum_events"
end
