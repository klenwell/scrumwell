class AddTableColumnsToScrumSprint < ActiveRecord::Migration[5.2]
  def change
    # From https://trello.com/c/F928vbbT
    add_column :scrum_sprints, :story_points_committed, :integer
    add_column :scrum_sprints, :story_points_completed, :integer
    add_column :scrum_sprints, :average_velocity, :decimal
    add_column :scrum_sprints, :average_story_size, :decimal
    add_column :scrum_sprints, :backlog_story_points, :integer
    add_column :scrum_sprints, :backlog_stories_count, :integer
    add_column :scrum_sprints, :wish_heap_stories_count, :integer
    add_column :scrum_sprints, :wish_heap_story_points, :integer
    add_column :scrum_sprints, :notes, :text
  end
end
