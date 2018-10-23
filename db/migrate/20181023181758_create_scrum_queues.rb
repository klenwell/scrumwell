class CreateScrumQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_queues do |t|
      t.belongs_to :scrum_board, foreign_key: true

      t.string :trello_list_id
      t.integer :trello_pos
      t.string :name

      t.date :started_on
      t.date :ended_on

      t.timestamps
    end
  end
end
