# rails g migration refactor_scrum_import_fields
class RefactorScrumImportFields < ActiveRecord::Migration[5.2]
  def change
    rename_column :scrum_backlogs, :last_pulled_at, :last_imported_at
    rename_column :scrum_boards, :last_pulled_at, :last_imported_at
    remove_column :scrum_boards, :last_board_activity_at
    rename_column :scrum_sprints, :last_pulled_at, :last_imported_at
    rename_column :user_stories, :last_pulled_at, :last_imported_at
    rename_column :wish_heaps, :last_pulled_at, :last_imported_at
  end
end
