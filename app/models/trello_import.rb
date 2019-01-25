class TrelloImport < ApplicationRecord
  BOARD_ACTION_IMPORT_LIMIT = 1000

  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board
  alias_attribute :events, :scrum_events

  validate :no_board_imports_in_progress, on: :create

  def import_board_lists
    queues = []

    scrum_board.trello_board.lists.each do |trello_list|
      queue = ScrumQueue.find_or_create_from_trello_list(scrum_board, trello_list)
      queues << queue
    end

    queues
  end

  def import_board_actions
    # Processes latest board actions to update sprints and board WIP.
    import_count = 0

    scrum_board.latest_trello_actions(BOARD_ACTION_IMPORT_LIMIT).each do |trello_action|
      event = ScrumEvent.create_from_trello_import(self, trello_action)
      import_count += 1
      LogService.dev event.to_stdout
    rescue StandardError => e
      LogService.dev "*** Error: #{e}"
    end

    import_count
  end

  def end_now
    update!(ended_at: Time.zone.now)
  end

  def err_now(import_error)
    update!(error: import_error.to_s, ended_at: Time.zone.now)
  end

  def complete?
    ended_at.present?
  end

  def erred?
    error.present?
  end

  def in_progress?
    status == 'in-progress'
  end

  def status
    return 'error' if erred?
    return 'complete' if complete?
    return 'timeout' if duration > 3600
    'in-progress'
  end

  def duration
    return Time.zone.now - created_at unless complete?
    ended_at - created_at
  end

  def first_event
    events.first
  end

  def last_event
    events.last
  end

  def events_period
    return nil if events.empty?
    (events.last.occurred_at - events.first.occurred_at).to_i / 1.day
  end

  # private

  def no_board_imports_in_progress
    errors.add(:scrum_board, "import already in progress") if scrum_board.import_in_progress?
  end
end
