class WipLog < ApplicationRecord
  ## Associations
  belongs_to :scrum_board
  belongs_to :scrum_event

  ## Aliases
  alias_attribute :board, :scrum_board
  alias_attribute :event, :scrum_event

  ## Callbacks
  before_create :compute_wip_fields
  after_create :update_daily_velocity

  ## Validations

  #
  # Class Methods
  #
  def self.create_from_event(scrum_event)
    WipLog.create!(event: scrum_event,
                   board: scrum_event.scrum_board,
                   occurred_at: scrum_event.occurred_at)
  end

  def self.daily_velocity_between(board, start_at, end_at)
    project_started_at = board.completed_queues.first.started_on.beginning_of_day
    start_at = [project_started_at, start_at].max
    end_at = [project_started_at, end_at].max
    range = start_at..end_at

    wip_logs = WipLog.where(board: board, occurred_at: range).order(occurred_at: 'asc')

    return 0 unless wip_logs.count > 0

    points = wip_logs.pluck(:points_completed).sum
    days = (end_at - start_at) / 1.day
    (points / days).to_d
  end

  #
  # Instance Methods
  #
  def story?
    event.eventable.is_a? ScrumStory
  end

  def story
    return nil unless story?
    event.eventable
  end

  def queue
    list_id = event.trello_data.dig('list', 'id')
    return nil unless list_id
    ScrumQueue.find_by(trello_list_id: list_id)
  end

  def new_queue
    return queue if event.creates_story? || event.reopens_story?
    return after_queue if event.moves_story?
    nil if event.closes_story?
  end

  def old_queue
    return nil if event.creates_story? || event.reopens_story?
    return before_queue if event.moves_story?
    queue if event.closes_story?
  end

  def before_queue
    list_before_id = event.trello_data.dig('listBefore', 'id')
    return nil unless list_before_id
    ScrumQueue.find_by(trello_list_id: list_before_id)
  end

  def after_queue
    list_after_id = event.trello_data.dig('listAfter', 'id')
    return nil unless list_after_id
    ScrumQueue.find_by(trello_list_id: list_after_id)
  end

  def story_points(queue=nil)
    return 0 if story.blank?
    in_wish_heap = queue.try('wish_heap?')
    points = story.try(:points) || 0
    estimated_points = story.try(:estimated_points) || 0
    in_wish_heap ? estimated_points : points
  end

  ## Special Methods
  def summary
    f = '[%s] %s :: %s -> %s %s ((dv: %s)) --> av: %s'
    format(f, occurred_at, event.action, old_queue.try(:name),
           new_queue.try(:name), wip, daily_velocity, (daily_velocity['d42'].to_d * 42 / 3).round)
  end

  private

  def compute_wip_fields
    self.points_completed = points_change_for_queue(:completed_sprint_queue?)
    self.wip_changes = compute_wip_changes
    self.wip = compute_wip
  end

  def update_daily_velocity
    # This needs to query the last event log after its saved. To avoid the infinite
    # loop in using in callback: https://stackoverflow.com/a/23147994/1093087
    return false unless daily_velocity.nil?
    self.daily_velocity = compute_daily_velocities
    save!
  end

  def points_change_for_queue(queue_key)
    is_old_queue = old_queue.try(queue_key)
    is_new_queue = new_queue.try(queue_key)
    gain = !is_old_queue && is_new_queue
    loss = is_old_queue && !is_new_queue

    # Need to determine which queue because we only want to estimate for wish heap
    queue = is_old_queue ? old_queue : new_queue
    points = story_points(queue)

    return points if gain
    return points * -1 if loss
    0
  end

  def compute_wip_changes
    {
      wish_heap: points_change_for_queue(:wish_heap?),
      project_backlog: points_change_for_queue(:project_backlog?),
      sprint_backlog: points_change_for_queue(:sprint_backlog?)
    }
  end

  # rubocop: disable Metrics/AbcSize
  def compute_wip
    last_wip_log = WipLog.order(:id).last
    last_wip = last_wip_log.present? ? last_wip_log.wip : {}
    this_wip = wip_changes

    wish_heap = last_wip.fetch('wish_heap', 0) + this_wip['wish_heap']
    project_backlog = last_wip.fetch('project_backlog', 0) + this_wip['project_backlog']
    sprint_backlog = last_wip.fetch('sprint_backlog', 0) + this_wip['sprint_backlog']
    total = wish_heap + project_backlog + sprint_backlog

    {
      wish_heap: wish_heap,
      project_backlog: project_backlog,
      sprint_backlog: sprint_backlog,
      total: total
    }
  end
  # rubocop: enable Metrics/AbcSize

  def compute_daily_velocities
    {
      d7: daily_velocity_over_range(7),
      d14: daily_velocity_over_range(14),
      d28: daily_velocity_over_range(28),
      d42: daily_velocity_over_range(42),
      all: all_time_daily_velocity
    }
  end

  def project_started_at
    board.completed_queues.first.started_on.beginning_of_day
  end

  def all_time_daily_velocity
    WipLog.daily_velocity_between(board, project_started_at, occurred_at)
  end

  def daily_velocity_over_range(days)
    end_at = occurred_at
    start_at = end_at - days.days
    WipLog.daily_velocity_between(board, start_at, end_at)
  end
end
