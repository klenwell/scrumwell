class CreateScrumSprints < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_sprints do |t|
      t.references :scrum_backlog, foreign_key: true
      t.string :trello_list_id
      t.integer :trello_pos
      t.string :name
      t.date :started_on
      t.date :ended_on
      t.datetime :last_pulled_at

      t.timestamps
    end
  end
end
