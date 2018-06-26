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

ActiveRecord::Schema.define(version: 2018_06_26_022024) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "scrum_backlogs", force: :cascade do |t|
    t.string "trello_board_id"
    t.string "name"
    t.string "trello_url"
    t.datetime "last_board_activity_at"
    t.datetime "last_pulled_at"
    t.bigint "scrum_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_project_id"], name: "index_scrum_backlogs_on_scrum_project_id"
  end

  create_table "scrum_projects", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "scrum_backlogs", "scrum_projects"
end
