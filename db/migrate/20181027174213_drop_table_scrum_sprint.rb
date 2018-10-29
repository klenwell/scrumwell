class DropTableScrumSprint < ActiveRecord::Migration[5.2]
  def change
    drop_table :user_stories
    drop_table :wish_heaps
    drop_table :scrum_sprints
  end
end
