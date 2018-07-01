class ScrumSprint < ApplicationRecord
  belongs_to :scrum_backlog

  alias_attribute :backlog, :scrum_backlog
end
