class ScrumStory < ApplicationRecord
  AGILE_TOOLS_PLUGIN_ID = '59d4ef8cfea15a55b0086614'.freeze

  ## Associations
  belongs_to :scrum_board
  belongs_to :scrum_queue, optional: true

  # rubocop: disable Rails/InverseOf
  has_many :scrum_events, -> { order(occurred_at: :desc) }, as: :eventable
  # rubocop: enable Rails/InverseOf

  ## Aliases

  ## Validations
  validates :trello_card_id, presence: true
  validates :title, presence: true

  ## Callbacks
  before_create :set_card_data

  #
  # Class Methods
  #
  def self.points_from_card(trello_card)
    agile_plugin = trello_card.plugin_data.find { |pd| pd.idPlugin == AGILE_TOOLS_PLUGIN_ID }
    agile_plugin.present? ? agile_plugin.value['points'].to_i : nil
  end

  #
  # Instance Methods
  #
  def estimated_points
    sized? ? points : scrum_board.sampled_story_size
  end

  def trello_card
    TrelloService.card(trello_card_id)
  end

  def completed_on
    return nil unless trello_data['due_complete']
    return nil unless trello_data['due']
    trello_data['due'].to_date
  end

  def last_activity_at
    trello_data['last_activity_date']
  end

  def change_queue(queue, **options)
    event = options[:event]
    updated = update!(scrum_queue: queue)

    update_story = event.present? && event.occurred_at > last_activity_at
    return updated unless update_story

    set_card_data
    save!
  end

  def close
    update!(scrum_queue: nil)
  end

  def reopen(**options)
    event = options[:event]
    return nil unless event

    trello_list_id = event.trello_data.dig('list', 'id')
    return nil unless trello_list_id

    queue = ScrumQueue.find_by(trello_list_id: trello_list_id)
    update!(scrum_queue: queue)
  end

  def groomed?
    scrum_queue.present? && !scrum_queue.wish_heap? && sized?
  end

  def sized?
    points.present? && points > 0
  end

  def closed?
    trello_data['closed']
  end

  private

  def set_card_data
    self.points = ScrumStory.points_from_card(trello_card)
    self.trello_data = trello_card
  end
end
