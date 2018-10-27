class ScrumQueue < ApplicationRecord
  ## Associations
  belongs_to :scrum_board
  has_many :scrum_stories, -> { order(created_at: :asc) }, dependent: :destroy,
                                                           inverse_of: :scrum_queue

  # rubocop: disable Rails/InverseOf
  has_many :scrum_events, -> { order(occurred_at: :desc) }, as: :eventable
  # rubocop: enable Rails/InverseOf

  ## Aliases
  alias_attribute :stories, :scrum_stories
  alias_attribute :events, :scrum_events

  ## Callbacks
  before_save :set_start_end_dates

  #
  # Class Methods
  #

  #
  # Instance Methods
  #
  def groomed_stories
    stories.select(&:groomed?)
  end

  def points
    return stories.sum(&:estimated_points) if wish_heap?
    groomed_stories.sum(&:points)
  end

  def trello_list
    TrelloService.list(trello_list_id)
  end

  def wish_heap?
    # Preferred version:
    return true if name.downcase.include?('wish heap')

    # Legacy version:
    name.downcase.include?('wish')
  end

  def project_backlog?
    # Preferred version:
    return true if name.downcase.include?('groom')

    # Legacy version:
    name.downcase.include?('backlog') && !name.downcase.include?('current')
  end

  def sprint_backlog?
    # Preferred version:
    return true if name.downcase.include?('sprint backlog')

    # Legacy version:
    name.downcase.include?('current')
  end

  # rubocop: disable Style/RescueModifier
  def completed_sprint_queue?
    name.downcase.include?('completed') &&
      (date_from_name.present? rescue false)
  end
  # rubocop: enable Style/RescueModifier

  def active_sprint?
    completed_sprint_queue? &&
      started_on <= Time.zone.today && ended_on >= Time.zone.today
  end

  def date_from_name
    Date.parse(name.delete("^0-9"))
  end

  def average_velocity
    scrum_board.average_velocity_on(ended_on)
  end

  def average_story_size
    scrum_board.average_story_size_on(ended_on)
  end

  def wish_heap_points
    scrum_board.backlog_points_on(ended_on)
  end

  def backlog_points
    scrum_board.wish_heap_points_on(ended_on)
  end

  private

  def set_start_end_dates
    return unless completed_sprint_queue?
    self.ended_on = date_from_name
    self.started_on = ended_on - ScrumBoard::DEFAULT_SPRINT_DURATION
  end
end
