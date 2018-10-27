class DropTableScrumBacklog < ActiveRecord::Migration[5.2]
  def change
    drop_table :scrum_backlogs
  end
end
