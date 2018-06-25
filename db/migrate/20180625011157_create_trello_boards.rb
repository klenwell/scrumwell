class CreateTrelloBoards < ActiveRecord::Migration[5.2]
  def change
    create_table :trello_boards do |t|
      t.string :trello_id
      t.string :name
      t.string :url
      t.references :scrum_project, foreign_key: true

      t.timestamps
    end
  end
end
