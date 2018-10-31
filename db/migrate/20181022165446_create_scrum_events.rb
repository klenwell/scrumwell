class CreateScrumEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :scrum_events do |t|

      # Polymorphic association
      # https://guides.rubyonrails.org/association_basics.html#polymorphic-associations
      # Other models should add this line: has_many :events, as: eventable
      t.references :eventable, polymorphic: true, index: true

      t.belongs_to :scrum_board, foreign_key: true

      # Mainly for tracking user story changes. Some examples:
      # :created, :closed, :deleted, :changed_queue, :changed_description, :changed_due_date,
      # :renamed, :repositioned, :completed, :reopened
      # https://gist.github.com/tatwell/b4ed8ccae38727ed637fc19e6965bbd7#file-actions-rb-L87
      t.string :action

      t.string :trello_id
      t.string :trello_type
      t.string :trello_object

      # https://edgeguides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb
      t.json :trello_data

      # Trello action date
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
