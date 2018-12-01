# rails g migration AddTrelloMemberIdToScrumEvent
class AddTrelloMemberIdToScrumEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :scrum_events, :trello_member_id, :string
    add_index :scrum_events, :trello_member_id
  end
end
