# rails g model TrelloImport scrum_board:references ended_at:datetime
class CreateTrelloImports < ActiveRecord::Migration[5.2]
  def change
    # TrelloImport belongs_to :scrum_board
    create_table :trello_imports do |t|
      t.references :scrum_board, foreign_key: true
      t.datetime :ended_at

      t.timestamps
    end

    # TrelloImport has_many :scrum_events
    add_reference :scrum_events, :trello_import, index: true
  end
end
