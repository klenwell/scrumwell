class ScrumStory < ApplicationRecord
  AGILE_TOOLS_PLUGIN_ID = '59d4ef8cfea15a55b0086614'.freeze

  ## Associations
  belongs_to :scrum_board
  belongs_to :scrum_queue

  # rubocop: disable Rails/InverseOf
  has_many :scrum_events, -> { order(occurred_at: :desc) }, as: :eventable
  # rubocop: enable Rails/InverseOf

  ## Validations
  validates :trello_card_id, presence: true
  validates :title, presence: true

  ## Callbacks
  before_create :set_card_data

  #
  # Class Methods
  #
  def self.create_from_board_event(board, scrum_event)
    queue = board.queue_by_trello_id(scrum_event.trello_list_id)

    story = ScrumStory.create!(
      scrum_board: board,
      scrum_queue: queue,
      trello_card_id: scrum_event.trello_card_id,
      title: scrum_event.trello_data.dig('card', 'name')
    )

    scrum_event.update!(eventable: story)
    story
  end

  def self.points_from_card(trello_card)
    agile_plugin = trello_card.plugin_data.find { |pd| pd.idPlugin == AGILE_TOOLS_PLUGIN_ID }
    agile_plugin.present? ? agile_plugin.value['points'].to_i : nil
  end

  #
  # Instance Methods
  #
  def trello_card
    TrelloService.card(trello_card_id)
  end

  private

  def set_card_data
    self.points = ScrumStory.points_from_card(trello_card)
    self.trello_data = trello_card
  end
end
