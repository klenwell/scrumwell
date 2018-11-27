class SprintContribution < ApplicationRecord
  belongs_to :scrum_contributor
  belongs_to :scrum_queue

  alias_attribute :contributor, :scrum_contributor
end
