class ScrumContributor < ApplicationRecord
  has_many :scrum_contributions, dependent: :destroy
  has_many :sprint_contributions, dependent: :destroy
  has_many :scrum_stories, through: :scrum_contributions
  has_many :scrum_queues, through: :scrum_stories
  has_many :scrum_events, primary_key: :trello_member_id, foreign_key: :trello_member_id,
                          dependent: :destroy, inverse_of: :scrum_contributor

  alias_attribute :contributions, :scrum_contributions
  alias_attribute :events, :scrum_events

  #
  # Class Methods
  #
  def self.create_from_trello_member(trello_member)
    ScrumContributor.create!(
      trello_member_id: trello_member.id,
      trello_url: trello_member.url,
      trello_avatar_url: trello_member.avatar_url,

      username: trello_member.username,
      full_name: trello_member.full_name,
      email: trello_member.email
    )
  end

  def self.find_or_create_by_trello_member_id(member_id)
    contributor = find_by(trello_member_id: member_id)
    return contributor if contributor.present?

    trello_member = TrelloService.member(member_id)
    return nil if trello_member.nil?

    ScrumContributor.create_from_trello_member(trello_member)
  end

  #
  # Instance Methods
  #
  def avatar_url
    nil_url = 'https://trello-avatars.s3.amazonaws.com//170.png'
    return nil if trello_avatar_url == nil_url
    trello_avatar_url
  end

  def story_points
    return 0 if scrum_stories.blank?
    scrum_stories.sum { |s| s.points.to_i }
  end

  def sprints
    scrum_queues.order(:ended_on).uniq
  end

  def completed_sprints
    scrum_queues.where('ended_on < ?', Time.zone.today).order(:ended_on).uniq
  end

  def points_for_sprint(sprint)
    scrum_stories.where(scrum_queue: sprint).sum { |s| s.points.to_i }
  end

  def sprint_points
    points = []

    completed_sprints.each do |sprint|
      points << points_for_sprint(sprint)
    end

    points
  end

  def avg_capacity
    last_three_sprints = sprint_points.last(3)
    1.0 * last_three_sprints.sum / last_three_sprints.length
  end
end