class CreateWipLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :wip_logs do |t|
      # Associations
      t.belongs_to :scrum_board, foreign_key: true
      t.belongs_to :scrum_event, foreign_key: true

      # Point change
      t.integer :point_change

      # Keys: :wish_heap, :project_backlog, :sprint_backlog, :total
      t.json :wip

      # Keys: :all, :d7, :d14, :d28, :d42
      t.json :daily_velocity

      t.timestamps
    end
  end
end
