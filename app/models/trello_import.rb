class TrelloImport < ApplicationRecord
  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board

  def end_now
    update(ended_at: Time.zone.now)
  end

  def complete?
    ended_at.present?
  end

  def status
    'TODO'
  end

  def duration
    return nil unless complete?
    ended_at - created_at
  end
end
