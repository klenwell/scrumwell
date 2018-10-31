class CreateWipLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :wip_logs do |t|
      # Associations
      t.belongs_to :scrum_board, foreign_key: true
      t.belongs_to :scrum_event, foreign_key: true

      # Story points completed
      t.integer :points_completed

      # Keys: :wish_heap, :project_backlog, :sprint_backlog, :total
      t.json :wip_changes

      # Keys: :wish_heap, :project_backlog, :sprint_backlog, :total
      t.json :wip

      # Keys: :all, :d7, :d14, :d28, :d42
      t.json :daily_velocity

      # Matches event value.
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
