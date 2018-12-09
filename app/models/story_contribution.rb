class StoryContribution < ApplicationRecord
  belongs_to :scrum_contributor
  belongs_to :scrum_story
end
