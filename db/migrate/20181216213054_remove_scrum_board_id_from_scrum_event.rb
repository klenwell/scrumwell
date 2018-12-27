# rails g migration RemoveScrumBoardIdFromScrumEvent
class RemoveScrumBoardIdFromScrumEvent < ActiveRecord::Migration[5.2]
  def change
    remove_column :scrum_events, :scrum_board_id
  end
end
