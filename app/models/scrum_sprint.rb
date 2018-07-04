class ScrumSprint < ApplicationRecord
  belongs_to :scrum_backlog
  has_many :user_stories, -> { order(trello_pos: :asc) }, dependent: :destroy,
                                                          inverse_of: :scrum_sprint

  alias_attribute :backlog, :scrum_backlog
  alias_attribute :stories, :user_stories

  #
  # Class Methods
  #
  def self.create_from_trello_list(scrum_backlog, trello_list)
    # https://stackoverflow.com/a/12858147/1093087
    name = trello_list.name.delete("^0-9")
    ends_on = Date.parse(name)
    starts_on = ends_on - ScrumBacklog::DEFAULT_SPRINT_DURATION

    sprint = ScrumSprint.create(scrum_backlog_id: scrum_backlog.id,
                                trello_list_id: trello_list.id,
                                trello_pos: trello_list.pos,
                                name: name,
                                started_on: starts_on,
                                ended_on: ends_on,
                                last_pulled_at: Time.now.utc)

    # Create associate user story cards.
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(sprint, card) if UserStory.user_story_card?(card)
    end

    sprint
  end

  def self.update_or_create_from_trello_list(scrum_backlog, trello_list)
    sprint = ScrumSprint.find_by(trello_list_id: trello_list.id)

    if sprint.present?
      sprint.trello_pos = trello_list.pos
      sprint.last_pulled_at = Time.now.utc
      sprint.save!
    else
      sprint = ScrumSprint.create_from_trello_list(scrum_backlog, trello_list)
    end

    sprint
  end

  def self.sprinty_trello_list?(trello_list)
    trello_list.name.downcase.include? 'complete'
  end

  #
  # Instance Methods
  #
  def current?
    !over? && !future?
  end

  def future?
    started_on > Time.zone.today
  end

  def over?
    ended_on < Time.zone.today
  end

  def story_points
    stories.sum(&:points)
  end
end
