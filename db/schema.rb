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

ActiveRecord::Schema.define(version: 2018_06_25_011157) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "scrum_projects", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trello_boards", force: :cascade do |t|
    t.string "trello_id"
    t.string "name"
    t.string "url"
    t.bigint "scrum_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scrum_project_id"], name: "index_trello_boards_on_scrum_project_id"
  end

  add_foreign_key "trello_boards", "scrum_projects"
end
