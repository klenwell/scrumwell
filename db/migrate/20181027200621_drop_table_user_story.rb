class DropTableUserStory < ActiveRecord::Migration[5.2]
  def change
    drop_table :user_stories
  end
end
