class TrelloImport < ApplicationRecord
  belongs_to :scrum_board
  has_many :scrum_events, dependent: :destroy

  alias_attribute :board, :scrum_board

  def complete?
    ended_at.present?
  end
end
