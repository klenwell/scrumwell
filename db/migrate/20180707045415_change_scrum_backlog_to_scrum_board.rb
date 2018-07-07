class ChangeScrumBacklogToScrumBoard < ActiveRecord::Migration[5.2]
  def change
    rename_table :scrum_backlog, :scrum_board
  end
end
