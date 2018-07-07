class ScrumBoard < ApplicationRecord
  has_many :scrum_sprints, -> { order(ended_on: :desc) }, dependent: :destroy,
                                                          inverse_of: :scrum_board
  has_many :wish_heaps, -> { order(trello_pos: :desc) }, dependent: :destroy,
                                                         inverse_of: :scrum_board
  has_one :scrum_backlog, dependent: :destroy

  alias_attribute :sprints, :scrum_sprints
  alias_attribute :backlog, :scrum_backlog

  DEFAULT_SPRINT_DURATION = 2.weeks

  validates :name, presence: true
  validates :trello_board_id, presence: true
  validates :trello_url, presence: true
  validate :trello_url_is_valid

  # Class Methods
  def self.by_trello_board_or_create(trello_board)
    scrum_board = ScrumBoard.find_by(trello_board_id: trello_board.id)

    if scrum_board
      scrum_board.update_from_trello_board(trello_board)
    else
      scrum_board = ScrumBoard.create_from_trello_board(trello_board)
    end

    scrum_board
  end

  def self.create_from_trello_board(trello_board)
    scrum_board = ScrumBoard.new(trello_board_id: trello_board.id,
                                 trello_url: trello_board.url,
                                 name: trello_board.name,
                                 last_board_activity_at: trello_board.last_activity_date,
                                 last_pulled_at: Time.now.utc)
    scrum_board.save!
    scrum_board.update_queues_from_trello_board(trello_board)
    scrum_board
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

  def self.sprinty_trello_list?(trello_list)
    trello_list.name.downcase.include? 'complete'
  end

  def self.wishy_trello_list?(trello_list)
    trello_list.name.downcase.include? 'wish'
  end

  def self.backloggy_trello_list?(trello_list)
    trello_list.name.downcase.include? 'backlog'
  end

  # Instance Methods
  def wish_heap
    wish_heaps.first
  end

  def current_sprint; end

  def completed_sprints
    sprints.keep_if(&:over?)
  end

  def wish_heap_story_count
    wish_heaps.sum(&:story_count)
  end

  def backlog_points
    # Safe navigation: https://stackoverflow.com/q/37977721/1093087
    backlog&.story_points
  end

  def update_from_trello_board(trello_board)
    update(trello_url: trello_board.url,
           last_board_activity_at: trello_board.last_activity_date,
           last_pulled_at: Time.now.utc)
  end

  def update_queues_from_trello_board(trello_board)
    trello_board.lists.each do |list|
      if ScrumBoard.wishy_trello_list?(list)
        WishHeap.update_or_create_from_trello_list(self, list)
      elsif ScrumBoard.sprinty_trello_list?(list)
        ScrumSprint.update_or_create_from_trello_list(self, list)
      elsif ScrumBoard.backloggy_trello_list?(list)
        ScrumBacklog.update_or_create_from_trello_list(self, list)
      end
    end
  end

  # Live board data from Trello API
  def live_board
    Rails.cache.fetch("scrum_board/trello_board/#{trello_board_id}", expires_in: 1.minute) do
      TrelloService.board(trello_board_id)
    end
  end

  private

  # Custom Validators
  def trello_url_is_valid
    return if trello_url.nil?
    url_start = 'https://trello.com/b'
    error_message = 'must be valid Trello url'
    errors.add(:trello_url, error_message) unless trello_url.downcase.start_with?(url_start)
  end
end
