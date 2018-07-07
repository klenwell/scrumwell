class MakeUserStoriesQueueable < ActiveRecord::Migration[5.2]
  def change
    rename_column :user_stories, :scrum_sprint_id, :queue_id
    add_column :user_stories, :queue_type, :string
    add_index :user_stories, [:queue_type, :queue_id]
    remove_index :user_stories, :queue_id
    remove_foreign_key :user_stories, :scrum_sprints if foreign_key_exists?(:accounts, :branches)
  end
end
