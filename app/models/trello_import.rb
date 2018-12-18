class TrelloImport < ApplicationRecord
  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board
  alias_attribute :events, :scrum_events

  def end_now
    update(ended_at: Time.zone.now)
  end

  def complete?
    ended_at.present?
  end

  def status
    return 'complete' if complete?
    'in-progress'
  end

  def duration
    return nil unless complete?
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
end
