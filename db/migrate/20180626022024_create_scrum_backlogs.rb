class CreateScrumBacklogs < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_backlogs do |t|
      t.string :trello_board_id
      t.string :name
      t.string :trello_url
      t.datetime :last_board_activity_at
      t.datetime :last_pulled_at
      t.references :scrum_project, foreign_key: true

      t.timestamps
    end
  end
end
