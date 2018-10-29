class ScrumBoard < ApplicationRecord
  ## Constants
  DEFAULT_SPRINT_DURATION = 2.weeks
  NUM_SPRINTS_FOR_AVG_VELOCITY = 3

  ## Associations
  has_many :scrum_queues, -> { order(ended_on: :asc) }, dependent: :destroy,
                                                        inverse_of: :scrum_board
  has_many :scrum_stories, -> { order(created_at: :asc) }, dependent: :destroy,
                                                           inverse_of: :scrum_board
  has_many :scrum_events, -> { order(occurred_at: :desc) }, dependent: :destroy,
                                                            inverse_of: :scrum_board
  has_many :wip_logs, -> { order(occurred_at: :desc) }, dependent: :destroy,
                                                        inverse_of: :scrum_board

  ## Aliases
  alias_attribute :queues, :scrum_queues
  alias_attribute :stories, :scrum_stories
  alias_attribute :events, :scrum_events

  ## Validators
  validates :name, presence: true
  validate :trello_url_is_valid

  #
  # Class Methods
  #
  def self.reconstruct_from_trello_board_actions(trello_board)
    scrum_board = ScrumBoard.create!(trello_board_id: trello_board.id,
                                     trello_url: trello_board.url,
                                     name: trello_board.name)

    scrum_board.import_trello_lists
    scrum_board.import_latest_trello_actions
    scrum_board.reload
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

  def recent_sized_stories
    # On reorder: https://stackoverflow.com/a/4202448/1093087
    stories.where('points > 0').reorder(created_at: :desc)
  end

  def sized_stories_before(date)
    sized_stories = stories.where('points > 0').select { |s| s.last_activity_at < date.end_of_day }
    sized_stories.sort_by(&:last_activity_at).reverse
  end

  def completed_queues
    queues.select(&:completed_sprint_queue?).sort_by(&:started_on)
  end

  def wip_events(options={})
    limit = options.fetch(:limit, 10)
    events.select(&:wip?).slice(0, limit)
  end

  #
  # Instance Methods
  #
  def build_wip_log_from_scratch
    wip_logs = []
    events.reverse_each do |event|
      next unless event.wip?
      wip_log = WipLog.create_from_event(event)
      puts wip_log.to_stdout if Rails.env.development? # rubocop: disable Rails/Output
      wip_logs << wip_log
    end
    wip_logs
  end

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

  def average_story_size_on(date)
    sample_size = 20
    sample = sized_stories_before(date).slice(0, sample_size)
    (sample.sum(&:points).to_d / sample.length).round(1)
  end

  def current_average_story_size
    average_story_size_on(Time.zone.today)
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

  def import_latest_trello_actions
    # Processes latest board actions to update sprints and board WIP.
    events = []

    latest_trello_actions.each do |trello_action|
      event = ScrumEvent.create_from_trello_board_event(self, trello_action)
      events << digest_latest_event(event)
      puts event.to_stdout if Rails.env.development? # rubocop: disable Rails/Output
    end

    events
  end

  def digest_latest_event(scrum_event)
    if scrum_event.creates_queue?
      scrum_event.create_queue_for_board(self)
    elsif scrum_event.creates_story?
      scrum_event.create_story_for_board(self)
    elsif scrum_event.moves_story?
      scrum_event.move_story
    elsif scrum_event.changes_story_status?
      scrum_event.update_story_status
    end

    scrum_event.reload
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

      # rubocop: disable Rails/Output
      if Rails.env.development?
        f = 'Fetched %s (%s) Trello board actions from API.'
        puts format(f, actions.length, latest_actions.length)
      end
      # rubocop: enable Rails/Output

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

  def trello_board
    return nil unless trello_board_id
    TrelloService.board(trello_board_id)
  end

  def queue_by_trello_id(trello_list_id)
    queues.find { |q| q.trello_list_id == trello_list_id }
  end

  def sampled_story_size
    sample_size = 20
    sample = recent_sized_stories.limit(sample_size)
    (sample.sum(&:points).to_d / sample.length).ceil
  end

  def import_trello_lists
    queues = []

    trello_board.lists.each do |trello_list|
      queue = ScrumQueue.find_or_create_from_trello_list(self, trello_list)
      queues << queue
    end

    queues
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
