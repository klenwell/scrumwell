# rails g migration add_scrum_story_count
class AddScrumStoryCountField < ActiveRecord::Migration[5.2]
  def change
    add_column :scrum_sprints, :stories_count, :integer
    remove_column :scrum_sprints, :average_story_size
  end
end
