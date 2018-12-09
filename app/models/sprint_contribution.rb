class SprintContribution < ApplicationRecord
  belongs_to :scrum_contributor
  belongs_to :scrum_queue

  alias_attribute :contributor, :scrum_contributor
  alias_attribute :queue, :scrum_queue

  #
  # Instance Methods
  #
  def to_stdout
    f = '#<SprintContribution id=%s contributor=%s queue=%s points=%s events=%s>'
    format(f, id, contributor.username, queue.name, story_points, event_count)
  end
end
