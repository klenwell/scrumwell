class ScrumQueue < ApplicationRecord
  ## Associations
  belongs_to :scrum_board
  has_many :scrum_stories, -> { order(created_at: :asc) }, dependent: :destroy,
                                                           inverse_of: :scrum_queue
  has_many :sprint_contributions, -> { order(story_points: :desc) }, dependent: :destroy,
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
  def self.create_from_trello_list(board, trello_list)
    ScrumQueue.create!(
      scrum_board: board,
      trello_list_id: trello_list.id,
      name: trello_list.name
    )
  end

  def self.find_or_create_from_trello_list(board, trello_list)
    queue = ScrumQueue.find_by(trello_list_id: trello_list.id)
    return queue if queue.present?

    ScrumQueue.create_from_trello_list(board, trello_list)
  end

  #
  # Instance Methods
  #
  def notes
    # TODO: add table column
    '(coming soon)'
  end

  def groomed_stories
    stories.select(&:groomed?)
  end

  def points
    return stories.sum(&:estimated_points) if wish_heap?
    groomed_stories.sum(&:points)
  end

  def event_contributors
    date_range = started_on.end_of_day..ended_on.end_of_day
    event_params = { occurred_at: date_range }
    import_params = { scrum_board_id: scrum_board.id }
    events = ScrumEvent.joins(:trello_import).where(scrum_events: event_params,
                                                    trello_imports: import_params)
    events.map(&:scrum_contributor).compact.flatten.uniq
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

  def backlog_points
    scrum_board.backlog_points_on(ended_on)
  end

  def wish_heap_points
    scrum_board.wish_heap_points_on(ended_on)
  end

  def over?
    ended_on < Time.zone.today
  end

  def to_stdout
    f = '#<ScrumQueue name=%s board=%s points=%s stories=%s, started_on=%s ended_on=%s>'
    format(f, name, scrum_board.name, points, stories.count, started_on, ended_on)
  end

  private

  def set_start_end_dates
    return unless completed_sprint_queue?
    self.ended_on = date_from_name
    self.started_on = ended_on - ScrumBoard::DEFAULT_SPRINT_DURATION
  end
end
