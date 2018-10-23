class ScrumBoard < ApplicationRecord
  has_many :scrum_sprints, -> { order(ended_on: :asc) }, dependent: :destroy,
                                                         inverse_of: :scrum_board
  has_many :scrum_queues, -> { order(ended_on: :asc) }, dependent: :destroy,
                                                        inverse_of: :scrum_board
  has_many :wish_heaps, -> { order(trello_pos: :desc) }, dependent: :destroy,
                                                         inverse_of: :scrum_board
  has_many :scrum_events, -> { order(occurred_at: :desc) }, dependent: :destroy,
                                                            inverse_of: :scrum_board
  has_one :scrum_backlog, dependent: :destroy

  DEFAULT_SPRINT_DURATION = 2.weeks
  NUM_SPRINTS_FOR_AVG_VELOCITY = 3

  alias_attribute :queues, :scrum_queues
  alias_attribute :events, :scrum_events

  # TODO: Remove
  alias_attribute :sprints, :scrum_sprints
  alias_attribute :backlog, :scrum_backlog

  validates :name, presence: true
  validate :trello_url_is_valid

  # Class Methods
  def self.reconstruct_from_trello_board_actions(trello_board)
    scrum_board = ScrumBoard.create!(trello_board_id: trello_board.id,
                                     trello_url: trello_board.url,
                                     name: trello_board.name)

    scrum_board.import_latest_trello_actions
  end

  def self.by_trello_board_or_create(trello_board)
    scrum_board = ScrumBoard.find_by(trello_board_id: trello_board.id)
    return scrum_board if scrum_board

    scrum_board = ScrumBoard.create_from_trello_board(trello_board)
    scrum_board
  end

  def self.create_from_trello_board(trello_board)
    scrum_board = ScrumBoard.create!(trello_board_id: trello_board.id,
                                     trello_url: trello_board.url,
                                     name: trello_board.name)
    logger.info "Created trello board #{scrum_board.name}."
    scrum_board.update_from_trello_board(trello_board)
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
  # Associations
  #
  def wish_heap
    queues.find(&:wish_heap?)
  end

  def project_backlog
    queues.find(&:project_backlog?)
  end

  def sprint_backlog
    queues.find(&:sprint_backlog?)
  end

  def active_sprint
    queues.find(&:active_sprint?)
  end

  #
  # Instance Methods
  #
  def import_latest_trello_actions
    # Processes latest board actions to update sprints and board WIP.
    events = []

    latest_trello_actions.each do |trello_action|
      event = ScrumEvent.from_trello_board_event(trello_board, trello_action)
      events << digest_latest_event(event)
    end

    events
  end

  def digest_latest_event(scrum_event)
    if scrum_event.creates_queue?
      create_queue_from_event(scrum_event)
    elsif scrum_event.creates_story?
      create_story_from_event(scrum_event)
    elsif scrum_event.moves_story?
      move_story_per_event(scrum_event)
    elsif scrum_event.changes_story_status?
      change_story_status_per_event(scrum_event)
    end
  end

  # rubocop: disable Metrics/AbcSize
  def latest_trello_actions
    latest_actions = []
    limit = 1000
    since_id = last_imported_action_id
    before_id = nil
    more = true
    calls = 0
    max_calls = 25

    while more
      # Rate limits: https://developers.trello.com/docs/rate-limits
      raise "Too many calls: #{calls}" if calls > max_calls

      actions = trello_board.actions(limit: limit, since: since_id, before: before_id)
      actions.each { |action| latest_actions << action }

      before_id = actions.last.id
      more = actions.length == limit
      calls += 1
    end

    # Actions come in reverse chronological order per https://stackoverflow.com/a/51817635/1093087
    latest_actions.reverse
  end
  # rubocop: enable Metrics/AbcSize

  def last_imported_action_id
    events.present? ? events.last.action.id : nil
  end

  # Trello Methods
  # Live board data from Trello API
  def trello_board
    return nil unless trello_board_id
    TrelloService.board(trello_board_id)
  end

  def update_from_trello_board(trello_board)
    update(trello_url: trello_board.url,
           last_imported_at: Time.now.utc)
    update_queues_from_trello_board(trello_board)
    recompute_sprint_metrics
  end

  def update_queues_from_trello_board(board)
    board.lists.each do |list|
      if ScrumBoard.wishy_trello_list?(list)
        WishHeap.update_or_create_from_trello_list(self, list)
      elsif ScrumBoard.backloggy_trello_list?(list)
        ScrumBacklog.update_or_create_from_trello_list(self, list)
      elsif ScrumBoard.sprinty_trello_list?(list)
        ScrumSprint.update_or_create_from_trello_list(self, list)
      end
    end
  end

  # Wish Heap Methods
  def deprecated_wish_heap
    wish_heaps.first
  end

  def wish_heap_story_count
    wish_heaps.sum(&:story_count)
  end

  def estimate_wish_heap_points
    # Avg Pts per Story * Num Wish Stories
    return nil if deprecated_wish_heap.nil?
    avg_pts_story = average_points_per_story
    return nil if avg_pts_story.nil? || deprecated_wish_heap.stories.empty?
    (avg_pts_story * deprecated_wish_heap.stories.length).round
  end

  def total_work_in_progress_points
    sprint_backlog_pts = sprint_backlog ? sprint_backlog.story_points : 0
    sprint_backlog_pts + backlog_points.to_i + estimate_wish_heap_points.to_i
  end

  # Backlog Methods
  def backlog_story_count
    backlog ? backlog.stories.count : 0
  end

  def backlog_points
    # Safe navigation: https://stackoverflow.com/q/37977721/1093087
    backlog&.story_points
  end

  # Sprint Backlog Methods
  def deprecated_sprint_backlog
    # This is the "current sprint" list in Trello Board.
    return nil unless trello_board
    needle = 'current'
    trello_list = trello_board.lists.find { |list| list.name.downcase.include? needle }
    ScrumSprint.sprint_backlog_from_trello_list(self, trello_list)
  end

  # Current Sprint Methods
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

  def story_points_committed
    current_sprint.story_points
  end

  # Completed Sprints
  def completed_sprints
    sprints.to_a.keep_if(&:over?)
  end

  def recent_sprints
    sprints.reverse
  end

  # Board Metrics
  def average_velocity
    last_sprint = completed_sprints.last
    return nil unless last_sprint
    average_velocity_for_sprint(last_sprint)
  end

  def average_points_per_story
    return nil if sprints.empty?

    total_story_points = 0
    user_story_count = 0
    sprint_count = 0

    sprints.each do |sprint|
      total_story_points += sprint.story_points
      user_story_count += sprint.stories_count
      sprint_count += 1
      break if sprint_count >= NUM_SPRINTS_FOR_AVG_VELOCITY + 1
    end

    1.0 * total_story_points / user_story_count
  end

  # Other Methods
  def recompute_sprint_metrics
    sprints.each(&:recompute!)
  end

  # rubocop: disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def average_velocity_for_sprint(sprint)
    previous_sprints_points = []
    previous_sprints_points << sprint.story_points_completed if sprint.over?

    completed_sprints.reverse_each do |completed_sprint|
      next if completed_sprint == sprint || completed_sprint.ended_after?(sprint)
      story_points = completed_sprint.story_points_completed || completed_sprint.story_points
      previous_sprints_points << story_points
      break if previous_sprints_points.length >= NUM_SPRINTS_FOR_AVG_VELOCITY
    end

    return nil if previous_sprints_points.blank?
    1.0 * previous_sprints_points.sum / previous_sprints_points.length
  end
  # rubocop: enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  private

  # Custom Validators
  def trello_url_is_valid
    return if trello_url.nil?
    url_start = 'https://trello.com/b'
    error_message = 'must be valid Trello url'
    errors.add(:trello_url, error_message) unless trello_url.downcase.start_with?(url_start)
  end
end
