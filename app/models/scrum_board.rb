class ScrumBoard < ApplicationRecord
  ## Constants
  DEFAULT_SPRINT_DURATION = 2.weeks
  NUM_SPRINTS_FOR_AVG_VELOCITY = 3

  ## Associations
  has_many :scrum_queues, -> { order(ended_on: :asc) }, dependent: :destroy,
                                                        inverse_of: :scrum_board
  has_many :scrum_stories, -> { order(created_at: :asc) }, dependent: :destroy,
                                                           inverse_of: :scrum_board
  has_many :trello_imports, -> { order(created_at: :desc) }, dependent: :destroy,
                                                             inverse_of: :scrum_board
  has_many :wip_logs, -> { order(occurred_at: :desc) }, dependent: :destroy,
                                                        inverse_of: :scrum_board
  has_many :scrum_events, -> { order(occurred_at: :desc) }, through: :trello_imports
  has_many :sprint_contributions, through: :scrum_queues

  ## Aliases
  alias_attribute :queues, :scrum_queues
  alias_attribute :stories, :scrum_stories
  alias_attribute :events, :scrum_events
  alias_attribute :imports, :trello_imports

  ## Validators
  validates :name, presence: true
  validate :trello_url_is_valid

  #
  # Class Methods
  #
  def self.find_or_create_by_trello_board(trello_board)
    # Find or create board.
    scrum_board = ScrumBoard.find_by(trello_board_id: trello_board.id)

    if scrum_board.nil?
      scrum_board = ScrumBoard.create!(trello_board_id: trello_board.id,
                                       trello_url: trello_board.url,
                                       name: trello_board.name)
    end

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

  def completed_queues
    queues.select(&:completed_sprint_queue?).sort_by(&:started_on)
  end

  def queue_by_trello_id(trello_list_id)
    queues.find { |q| q.trello_list_id == trello_list_id }
  end

  def recent_sized_stories
    # On reorder: https://stackoverflow.com/a/4202448/1093087
    stories.where('points > 0').reorder(created_at: :desc)
  end

  def sized_stories_before(date)
    sized_stories = stories.where('points > 0').select { |s| s.last_activity_at < date.end_of_day }
    sized_stories.sort_by(&:last_activity_at).reverse
  end

  def wip_events(options={})
    limit = options.fetch(:limit, 10)
    events.select(&:wip?).slice(0, limit)
  end

  def trello_board
    return nil unless trello_board_id
    TrelloService.board(trello_board_id)
  end

  def import_in_progress?
    imports.select(&:in_progress?).present?
  end

  #
  # Instance Methods
  #
  ## Action / Event Imports
  def update_from_trello(trello_import)
    # Import lists and actions.
    trello_import.import_board_lists
    trello_import.import_board_actions

    # Build WipLogs and SprintContributions
    build_wip_log_from_scratch
    build_sprint_contributions_from_scratch

    # Conclude
    trello_import.end_now
    trello_import
  end

  # rubocop: disable Metrics/AbcSize
  def latest_trello_actions(count=1000)
    # Board actions are ordered in DESC order: most recent are first. So to pull the latest,
    # need to import since last imported id going backwards.
    latest_actions = []
    request_limit = 1000
    since_id = last_imported_action_id
    before_id = nil
    more = true
    calls = 0
    max_calls = 100

    while more
      # Rate limits: https://developers.trello.com/docs/rate-limits
      raise "Too many calls: #{calls}" if calls > max_calls
      calls += 1

      actions = trello_board.actions(limit: request_limit, since: since_id, before: before_id)
      actions.each { |action| latest_actions << action }

      LogService.dev format('Fetched %s (%s) Trello board actions from API.',
                            actions.length,
                            latest_actions.length)

      more = actions.length == request_limit
      before_id = actions.last.id if more
    end

    # Actions come in reverse chronological order per https://stackoverflow.com/a/51817635/1093087
    latest_actions.reverse.slice(0, count)
  end
  # rubocop: enable Metrics/AbcSize

  def last_event
    events.try(:first)
  end

  def last_imported_action_id
    # events are sorted in desc order.
    last_event.present? ? last_event.trello_id : nil
  end

  def created_on
    events.find_by(trello_type: "createBoard").try(:occurred_at).to_date
  end

  ## WIP Logs
  def build_wip_log_from_scratch
    new_logs = []
    wip_logs.destroy_all

    events.reverse_each do |event|
      next unless event.wip?
      wip_log = WipLog.create_from_event(event)
      LogService.dev wip_log.to_stdout
      new_logs << wip_log
    end

    new_logs
  end

  def current_wip
    return nil if wip_logs.blank?
    wip_logs.first.wip['total']
  end

  def backlog_points_on(date)
    logs = wip_logs.where('occurred_at <= ?', date.end_of_day).order(occurred_at: :desc).limit(1)
    logs.count > 0 ? logs.first.wip['project_backlog'] : nil
  end

  def wish_heap_points_on(date)
    logs = wip_logs.where('occurred_at <= ?', date.end_of_day).order(occurred_at: :desc).limit(1)
    logs.count > 0 ? logs.first.wip['wish_heap'] : nil
  end

  ## Sprint Contributions
  def build_sprint_contributions_from_scratch
    # To be considered active that sprint event without contributing story points.
    min_events_to_be_active = 3
    saved_contributions = []

    # For each completed sprint...
    completed_queues.each do |queue|
      # From scratch...
      queue.sprint_contributions.destroy_all

      # Add a contribution for each contributor who performed the min events/actions.
      # This will capture any contributors who may have contributed 0 story points.
      queue.event_contributors.each do |contributor|
        event_count = contributor.count_events_for_queue(queue)
        next unless event_count >= min_events_to_be_active

        sprint_contrib = SprintContribution.create(
          scrum_contributor: contributor,
          scrum_queue: queue,
          story_points: contributor.points_for_sprint(queue),
          event_count: event_count
        )

        LogService.dev sprint_contrib.to_stdout
        saved_contributions << sprint_contrib
      end
    end

    saved_contributions
  end

  ## Velocity
  def average_velocity_on(date)
    # Averaged over last 3 sprints
    period = DEFAULT_SPRINT_DURATION * NUM_SPRINTS_FOR_AVG_VELOCITY
    days_in_sprint = DEFAULT_SPRINT_DURATION.to_i / 1.day.to_i

    end_at = date.end_of_day
    start_at = end_at - period
    daily_velocity = WipLog.daily_velocity_between(self, start_at, end_at)

    (daily_velocity * days_in_sprint).round(1)
  end

  def current_velocity
    average_velocity_on(Time.zone.today)
  end

  ## Story Size
  def average_story_size_on(date)
    sample_size = 20
    sample = sized_stories_before(date).slice(0, sample_size)
    (sample.sum(&:points).to_d / sample.length).round(1)
  end

  def current_average_story_size
    average_story_size_on(Time.zone.today)
  end

  def sampled_story_size
    sample_size = 20
    sample = recent_sized_stories.limit(sample_size)
    (sample.sum(&:points).to_d / sample.length).ceil
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
