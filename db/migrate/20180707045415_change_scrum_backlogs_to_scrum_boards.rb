class ChangeScrumBacklogsToScrumBoards < ActiveRecord::Migration[5.2]
  def change
    rename_table :scrum_backlogs, :scrum_boards
    rename_column :scrum_sprints, :scrum_backlog_id, :scrum_board_id
  end
end
