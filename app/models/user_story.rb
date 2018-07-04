class UserStory < ApplicationRecord
  belongs_to :scrum_sprint, optional: true
end
