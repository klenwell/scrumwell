class CreateWishHeaps < ActiveRecord::Migration[5.2]
  def change
    create_table :wish_heaps do |t|
      t.references :scrum_board, foreign_key: true
      t.string :trello_list_id
      t.integer :trello_pos
      t.string :name
      t.datetime :last_pulled_at

      t.timestamps
    end
  end
end
