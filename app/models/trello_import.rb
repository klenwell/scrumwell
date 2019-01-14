class TrelloImport < ApplicationRecord
  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board
  alias_attribute :events, :scrum_events

  validate :no_board_imports_in_progress, on: :create

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
