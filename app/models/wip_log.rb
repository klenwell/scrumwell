class WipLog < ApplicationRecord
  ## Associations
  belongs_to :scrum_board
  belongs_to :scrum_event

  ## Aliases
  alias_attribute :board, :scrum_board
  alias_attribute :event, :scrum_event

  ## Callbacks
  before_validation :compute_wip_fields

  #
  # Class Methods
  #
  def self.create_from_event(scrum_event)
    WipLog.create!(event: scrum_event,
                   board: scrum_event.scrum_board,
                   occurred_at: scrum_event.occurred_at)
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
    f = '[%s] %s:%s :: %s -> %s %s'
    format(f, occurred_at, event.trello_object, event.action, old_queue.try(:name),
           new_queue.try(:name), wip)
  end

  private

  def compute_wip_fields
    self.points_completed = points_change_for_queue(:completed_sprint_queue?)
    self.wip_changes = compute_wip_changes
    self.wip = compute_wip
    self.daily_velocity = compute_daily_velocities
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
      d7: 0,
      d14: 0,
      d28: 0,
      d42: 0,
      all: 0
    }
  end
end
