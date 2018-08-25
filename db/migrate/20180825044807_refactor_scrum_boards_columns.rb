class RefactorScrumBoardsColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :scrum_boards, :name, :trello_name
    rename_column :scrum_boards, :last_pulled_at, :last_imported_at
    add_column :scrum_boards, :local_name, :string
    remove_column :scrum_boards, :last_board_activity_at
  end
end
