class CreateUserStories < ActiveRecord::Migration[5.2]
  def change
    create_table :user_stories do |t|
      t.references :scrum_sprint, foreign_key: true
      t.string :trello_card_id
      t.string :trello_short_url
      t.text :trello_name
      t.text :title
      t.text :description
      t.integer :points
      t.datetime :completed_at
      t.datetime :last_activity_at
      t.datetime :last_pulled_at

      t.timestamps
    end
  end
end
