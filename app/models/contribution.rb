class Contribution < ApplicationRecord
  belongs_to :contributor
  belongs_to :scrum_story
end
