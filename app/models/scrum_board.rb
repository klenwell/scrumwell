class ScrumBoard < ApplicationRecord
  has_many :scrum_sprints, -> { order(ended_on: :desc) }, dependent: :destroy,
                                                          inverse_of: :scrum_board
  has_many :wish_heaps, -> { order(trello_pos: :desc) }, dependent: :destroy,
                                                         inverse_of: :scrum_board
  has_one :scrum_backlog, dependent: :destroy

  alias_attribute :sprints, :scrum_sprints
  alias_attribute :backlog, :scrum_backlog

  DEFAULT_SPRINT_DURATION = 2.weeks
  NUM_SPRINTS_FOR_AVG_VELOCITY = 3

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
    scrum_board.recompute_sprint_metrics
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

  #
  # Instance Methods
  #
  def wish_heap
    wish_heaps.first
  end

  def sprint_backlog
    # This is the "current sprint" list in Trello Board.
    needle = 'current'
    trello_list = trello_board.lists.find { |list| list.name.downcase.include? needle }
    ScrumSprint.sprint_backlog_from_trello_list(self, trello_list)
  end

  # rubocop: disable Style/SafeNavigation
  # Simpler just to check if sprint_completed than to try to use SafeNav &. syntax.
  def current_sprint
    # Merge stories for current sprint (i.e. completed stories) into sprint backlog.
    # Creates an unsaved temporary ScrumSprint to represent current sprint, which spans
    # the sprint backlog (i.e. "Current Sprint" Trello list) and current completed
    # sprint ScrumSprint.
    tmp_sprint = sprint_backlog
    sprint_completed = sprints.find(&:current?)
    sprint_completed.stories.each { |story| tmp_sprint.stories << story } if sprint_completed
    tmp_sprint
  end
  # rubocop: enable Style/SafeNavigation

  def completed_sprints
    sprints.to_a.keep_if(&:over?)
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

  def recompute_sprint_metrics
    sprints.each(&:recompute!)
  end

  def story_points_committed
    current_sprint.story_points
  end

  def average_velocity_for_sprint(sprint)
    previous_sprints = []

    completed_sprints.each do |completed_sprint|
      next unless sprint == completed_sprint || sprint.ended_after?(completed_sprint)
      previous_sprints << completed_sprint
      break if previous_sprints.length >= NUM_SPRINTS_FOR_AVG_VELOCITY
    end

    return nil if previous_sprints.blank?
    1.0 * previous_sprints.sum(&:story_points) / previous_sprints.length
  end

  def average_velocity
    last_sprint = completed_sprints.first
    return nil unless last_sprint
    average_velocity_for_sprint(last_sprint)
  end

  def estimate_wish_heap_points
    # Avg Pts per Story * Num Wish Stories
    avg_pts_story = average_points_per_story
    return nil if avg_pts_story.nil? || wish_heap.stories.empty?
    (avg_pts_story * wish_heap.stories.length).round
  end

  def total_work_in_progress_points
    sprint_backlog.story_points + backlog_points + estimate_wish_heap_points
  end

  def average_points_per_story
    total_story_points = 0
    user_story_count = 0
    sprint_count = 0

    sprints.each do |sprint|
      total_story_points += sprint.story_points
      user_story_count += sprint.stories.length
      sprint_count += 1
      break if sprint_count >= NUM_SPRINTS_FOR_AVG_VELOCITY + 1
    end

    1.0 * total_story_points / user_story_count
  end

  # Live board data from Trello API
  def trello_board
    TrelloService.board(trello_board_id)
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
