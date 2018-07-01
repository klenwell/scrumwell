class CreateScrumBacklogs < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_backlogs do |t|
      t.string :trello_board_id
      t.string :trello_url
      t.string :name
      t.datetime :last_board_activity_at
      t.datetime :last_pulled_at

      t.timestamps
    end
  end
end
