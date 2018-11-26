# rails g model Contribution contributor_id:integer scrum_story_id:integer
# https://rubyplus.com/articles/3451
class CreateContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_contributions do |t|
      t.integer :scrum_contributor_id
      t.integer :scrum_story_id

      t.timestamps
    end
  end
end
