class AddLastActivityToScrumStory < ActiveRecord::Migration[5.2]
  def change
    # From https://trello.com/c/ie6ycKeO
    add_column :scrum_stories, :last_activity_at, :datetime
  end
end
