class CreateNewScrumBacklogs < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_backlogs do |t|
      t.references :scrum_board, foreign_key: true
      t.string :trello_list_id
      t.string :trello_pos
      t.string :name
      t.datetime :last_pulled_at

      t.timestamps
    end
    add_index :scrum_backlogs, :trello_list_id
  end
end
