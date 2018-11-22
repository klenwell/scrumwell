class Contributor < ApplicationRecord
  has_many :contributions, dependent: :destroy
  has_many :scrum_stories, through: :contributions
end
