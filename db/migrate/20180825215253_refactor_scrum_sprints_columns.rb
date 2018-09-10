# rails g migration refactor_scrum_sprints_columns
class RefactorScrumSprintsColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :scrum_sprints, :name, :trello_name
    add_column :scrum_sprints, :local_name, :string
    rename_column :scrum_sprints, :last_pulled_at, :last_imported_at
    rename_column :scrum_sprints, :story_points_committed, :trello_story_points_committed
    add_column :scrum_sprints, :local_story_points_committed, :integer
    rename_column :scrum_sprints, :story_points_completed, :trello_story_points_completed
    add_column :scrum_sprints, :local_story_points_completed, :integer
    add_column :scrum_sprints, :local_user_story_count, :integer
    rename_column :scrum_sprints, :average_velocity, :trello_average_velocity
    add_column :scrum_sprints, :local_average_velocity, :decimal
  end
end
