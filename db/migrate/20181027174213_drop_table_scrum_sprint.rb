class DropTableScrumSprint < ActiveRecord::Migration[5.2]
  def change
    drop_table :scrum_sprints
  end
end
