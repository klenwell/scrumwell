class TrelloImport < ApplicationRecord
  BOARD_ACTION_IMPORT_LIMIT = 1000
  STALLED_IMPORT_TIME_LIMIT = 30.seconds

  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board
  alias_attribute :events, :scrum_events

  validate :no_board_imports_in_progress, on: :create

  # Imports full board from Trello all at once.
  # rubocop: disable Metrics/AbcSize
  def self.import_full_board(trello_board_id)
    # Create board and import.
    trello_board = TrelloService.board(trello_board_id)
    scrum_board = ScrumBoard.find_or_create_by_trello_board(trello_board)
    trello_import = TrelloImport.create(scrum_board: scrum_board)

    # Import board lists.
    trello_import.import_board_lists

    # Import board actions.
    scrum_board.latest_trello_actions(100_000).each do |trello_action|
      event = ScrumEvent.create_from_trello_import(trello_import.id, trello_action)
      ImportLogger.debug event.to_stdout
    rescue StandardError => e
      ImportLogger.error format("%s: %s", trello_action, e)
    end

    # Build WipLogs and SprintContributions
    scrum_board.build_wip_log_from_scratch
    scrum_board.build_sprint_contributions_from_scratch

    # Conclude
    trello_import.end_now
    trello_import
  end
  # rubocop: enable Metrics/AbcSize

  def import_board_lists
    queues = []

    scrum_board.trello_board.lists.each do |trello_list|
      queue = ScrumQueue.find_or_create_from_trello_list(scrum_board, trello_list)
      queues << queue
    end

    queues
  end

  def latest_board_actions
    # Processes latest board actions to update sprints
    import_count = 0

    scrum_board.latest_trello_actions(BOARD_ACTION_IMPORT_LIMIT).each do |trello_action|
      event = ScrumEvent.create_from_trello_import(self, trello_action)
      import_count += 1
      ImportLogger.debug event.to_stdout
    rescue StandardError => e
      # If error, log error and stop
      ImportLogger.error format('%s: %s', e, trello_action)
      err_now(e)
      return import_count
    end

    import_count
  end

  def update_sprints
    # Update wish heap

    # Update backlog

    # Update current sprint

    # Update recently completed sprints
  end

  def end_now
    update!(ended_at: Time.zone.now)
  end

  def err_now(import_error)
    update!(error: import_error.to_s, ended_at: Time.zone.now)
  end

  def abort_now
    update!(error: 'aborted', ended_at: Time.zone.now)
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

  def stuck?
    in_progress? &&
    duration > STALLED_IMPORT_TIME_LIMIT &&
    events.count < 1
  end

  def aborted?
    erred? && error == 'aborted'
  end

  def status
    return 'error' if erred?
    return 'complete' if complete?
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
