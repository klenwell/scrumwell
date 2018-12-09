# rails g model SprintContribution scrum_contributor_id:integer scrum_queue_id:integer
class CreateSprintContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :sprint_contributions do |t|
      t.integer :scrum_contributor_id
      t.integer :scrum_queue_id
      
      t.integer :story_points
      t.integer :event_count

      t.timestamps
    end
  end
end
