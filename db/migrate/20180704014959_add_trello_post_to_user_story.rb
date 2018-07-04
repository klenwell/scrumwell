class AddTrelloPostToUserStory < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stories, :trello_pos, :integer
  end
end
