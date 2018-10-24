class ScrumQueue < ApplicationRecord
  ## Associations
  belongs_to :scrum_board
  has_many :scrum_events, -> { order(occurred_at: :desc) }, as: :eventable

  ## Aliases
  alias_attribute :events, :scrum_events

  ## Callbacks
  before_save :set_start_end_dates

  #
  # Class Methods
  #
  def self.create_from_board_event(board, scrum_event)
    queue = ScrumQueue.new(
      scrum_board: board,
      trello_list_id: scrum_event.trello_data['list']['id']
    )

    # Use current name rather than original as a key (WIP) queue could have been renamed.
    queue.name = queue.trello_list.name
    queue.save!

    scrum_event.update!(eventable: queue)
    queue
  end

  #
  # Instance Methods
  #
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
    return true if name.downcase.include?('project backlog')

    # Legacy version:
    name.downcase.include?('backlog')
  end

  def sprint_backlog?
    # Preferred version:
    return true if name.downcase.include?('sprint backlog')

    # Legacy version:
    name.downcase.include?('current')
  end

  def completed_sprint_queue?
    name.downcase.include?('completed') &&
      (date_from_name.present? rescue false)
  end

  def active_sprint?
    completed_sprint_queue? &&
      started_on <= Time.zone.today && ended_on >= Time.zone.today
  end

  def date_from_name
    Date.parse(name.delete("^0-9"))
  end

  private

  def set_start_end_dates
    if completed_sprint_queue?
      self.ended_on = date_from_name
      self.started_on = self.ended_on - ScrumBoard::DEFAULT_SPRINT_DURATION
    end
  end
end
