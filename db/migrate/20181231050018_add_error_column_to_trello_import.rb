# rails g migration AddErrorColumnToTrelloImport
class AddErrorColumnToTrelloImport < ActiveRecord::Migration[5.2]
  def change
    add_column :trello_imports, :error, :string
  end
end
