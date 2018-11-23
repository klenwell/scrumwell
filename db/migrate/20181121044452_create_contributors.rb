# rails g model Contributor trello_id:string trello_url:string trello_avatar_url:string...
# Trello docs: https://developers.trello.com/v1.0/reference#member-object
class CreateContributors < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_contributors do |t|
      t.string :username
      t.string :full_name
      t.string :email

      t.string :trello_member_id
      t.string :trello_url
      t.string :trello_avatar_url

      t.timestamps
    end
  end
end
