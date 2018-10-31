class CreateScrumStories < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_stories do |t|
      t.belongs_to :scrum_board, foreign_key: true
      t.belongs_to :scrum_queue, foreign_key: true

      t.string :trello_card_id
      t.text :title
      t.integer :points

      # https://developers.trello.com/v1.0/reference#cardsid
      t.json :trello_data

      t.timestamps
    end
  end
end
