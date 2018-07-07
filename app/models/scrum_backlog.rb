class ScrumBacklog < ApplicationRecord
  has_many :scrum_sprints, -> { order(ended_on: :desc) }, dependent: :destroy,
                                                          inverse_of: :scrum_backlog

  attr_accessor :api
  alias_attribute :sprints, :scrum_sprints

  DEFAULT_SPRINT_DURATION = 2.weeks

  validates :name, :trello_board_id, :trello_url, presence: true
  validate :trello_url_is_valid

  # Class Methods
  def self.create_from_trello_board(trello_board)
    backlog = ScrumBacklog.new(trello_board_id: trello_board.id,
                               trello_url: trello_board.url,
                               name: trello_board.name,
                               last_board_activity_at: trello_board.last_activity_date,
                               last_pulled_at: Time.now.utc)
    backlog.save!

    trello_board.lists.each do |list|
      if ScrumSprint.sprinty_trello_list?(list)
        ScrumSprint.update_or_create_from_trello_list(backlog, list)
      end
    end

    backlog
  end

  def self.scrummy_trello_board?(trello_board)
    # A scrummy board will contain these lists: wish heap, backlog, current
    scrummy_list_names = ['wish heap', 'backlog', 'current']
    board_list_names = trello_board.lists.map { |list| list.name.downcase.strip }

    scrummy_list_names.each do |required_name|
      return false unless board_list_names.any? { |list_name| list_name.include? required_name }
    end

    true
  end

  def self.by_trello_board_or_new(trello_board)
    backlog = ScrumBacklog.find_by(trello_board_id: trello_board.id)

    if backlog
      backlog.trello_url = trello_board.url
      backlog.last_board_activity_at = trello_board.last_activity_date
      backlog.last_pulled_at = Time.now.utc
    else
      backlog = ScrumBacklog.create_from_trello_board(trello_board)
    end

    backlog
  end

  # Instance Methods
  def wish_heap
    Rails.cache.fetch('scrum_backlog/wish_heap', expires_in: 1.minute) do
      wish_heap_list = live_board.lists.find { |list| list.name.downcase.include? 'wish heap' }
      wish_heap_list_to_sprint(wish_heap_list)
    end
  end

  def backlog; end

  def current_sprint; end

  def completed_sprints; end

  # Live board data from Trello API
  def live_board
    Rails.cache.fetch("scrum_backlog/trello_board/#{trello_board_id}", expires_in: 1.minute) do
      TrelloService.board(trello_board_id)
    end
  end

  private

  def wish_heap_list_to_sprint(wish_heap_list)
    sprint = ScrumSprint.new(scrum_backlog_id: id,
                             trello_list_id: wish_heap_list.id,
                             trello_pos: wish_heap_list.pos,
                             name: wish_heap_list.name,
                             last_pulled_at: Time.now.utc)
    sprint.stories = wish_heap_cards_to_stories(wish_heap_list)
    sprint
  end

  def wish_heap_cards_to_stories(wish_heap_list)
    # Associate user story cards.
    stories = []

    wish_heap_list.cards.each do |card|
      next unless UserStory.user_story_card?(card)
      story = UserStory.new(trello_card_id: card.id,
                            trello_short_url: card.short_url,
                            trello_pos: card.pos,
                            trello_name: card.name,
                            description: card.desc,
                            points: UserStory.story_points_from_card(card),
                            last_activity_at: card.last_activity_date,
                            last_pulled_at: Time.zone.now)
      stories << story
    end

    stories
  end

  # Custom Validators
  def trello_url_is_valid
    return if trello_url.nil?
    url_start = 'https://trello.com/b'
    error_message = 'must be valid Trello url'
    errors.add(:trello_url, error_message) unless trello_url.downcase.start_with?(url_start)
  end
end
