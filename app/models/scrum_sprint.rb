class ScrumSprint < ApplicationRecord
  belongs_to :scrum_board
  has_many :user_stories, -> { order(trello_pos: :asc) }, as: :queue,
                                                          dependent: :destroy,
                                                          inverse_of: :queue

  alias_attribute :board, :scrum_board
  alias_attribute :stories, :user_stories
  alias_attribute :story_count, :user_story_count

  before_save :assign_computed_fields

  validates :started_on, presence: true
  validates :ended_on, presence: true
  validates :story_points_completed, presence: true
  validate :name_is_valid
  validate :story_points_are_valid

  #
  # Virtual Fields
  #
  def name
    local_name || trello_name
  end

  def story_points_committed
    local_story_points_committed || trello_story_points_committed
  end

  def story_points_completed
    local_story_points_completed || trello_story_points_completed
  end

  def user_story_count
    local_user_story_count || stories.count
  end

  def average_velocity
    local_average_velocity || trello_average_velocity
  end

  #
  # Class Methods
  #
  def self.update_or_create_from_trello_list(scrum_board, trello_list)
    sprint = ScrumSprint.find_by(trello_list_id: trello_list.id)

    if sprint.present?
      sprint.scrum_board_id = scrum_board.id
      sprint.trello_pos = trello_list.pos
      sprint.last_pulled_at = Time.now.utc
      sprint.save!
      sprint.save_stories_from_trello_list(trello_list)
    else
      sprint = ScrumSprint.create_from_trello_list(scrum_board, trello_list)
    end

    sprint
  end

  def self.create_from_trello_list(scrum_board, trello_list)
    # https://stackoverflow.com/a/12858147/1093087
    name = trello_list.name.delete("^0-9")
    ends_on = Date.parse(name)
    starts_on = ends_on - ScrumBoard::DEFAULT_SPRINT_DURATION

    sprint = ScrumSprint.create!(scrum_board_id: scrum_board.id,
                                 trello_list_id: trello_list.id,
                                 trello_pos: trello_list.pos,
                                 trello_name: trello_list.name,
                                 local_name: name,
                                 started_on: starts_on,
                                 ended_on: ends_on,
                                 trello_story_points_completed: 0,
                                 last_imported_at: Time.now.utc)
    sprint.save_stories_from_trello_list(trello_list)
    sprint
  end

  def self.sprint_backlog_from_trello_list(scrum_board, trello_list)
    # Returns a temporary unsaved record from scrum backlog ("Current Sprint") column.
    backlog = ScrumSprint.new(scrum_board_id: scrum_board.id,
                              trello_list_id: trello_list.id,
                              trello_pos: trello_list.pos,
                              trello_name: trello_list.name,
                              last_imported_at: Time.now.utc)

    # Attach cards
    trello_list.cards.each do |card|
      next unless UserStory.user_story_card?(card)
      backlog.stories << UserStory.new_from_trello_card(card)
    end

    backlog
  end

  def self.name_from_date(date)
    format('Sprint %s Completed', date.strftime('%Y%m%d'))
  end

  def self.end_date_from_name(name)
    Date.parse(name.delete("^0-9"))
  end

  #
  # Instance Methods
  #
  def update_from_trello_list
    trello_list = TrelloService.list(trello_list_id)
    return unless trello_list

    self.trello_pos = trello_list.pos
    self.last_pulled_at = Time.now.utc
    save!
    save_stories_from_trello_list(trello_list)
  end

  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
    end
    recompute_and_save
  end

  def story_points
    stories ? stories.sum(&:points) : story_points_completed
  end

  def story_count
    if stories.empty? && average_story_size && story_points_completed
      (story_points_completed / average_story_size).round
    else
      stories.count
    end
  end

  def current?
    !over? && !future?
  end

  def future?
    started_on > Time.zone.today
  end

  def over?
    ended_on < Time.zone.today
  end

  def ended_after?(other_sprint)
    ended_on > other_sprint.ended_on
  end

  def age
    Time.zone.today - started_on
  end

  def recompute!
    # Force an update to run assign_computed_fields callbacks.
    update(updated_at: Time.zone.now)
  end

  def recompute_and_save
    force_reassignment = true
    assign_computed_fields(force_reassignment)
    save!
  end

  # private

  def assign_computed_fields(force=false)
    # Need to reload stories to compute points accurately.
    # Reference: https://stackoverflow.com/a/29280034/1093087
    stories.reset
    assign_computed_fields_for_completed_sprint(force)
    assign_computed_fields_for_current_sprint
  end

  # rubocop: disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def assign_computed_fields_for_completed_sprint(force=false)
    return unless over?
    self.trello_average_velocity = board.average_velocity_for_sprint(self)

    # Only recompute field below when empty or forced.
    saved_story_pts = force ? 0 : story_points_completed.to_i
    saved_avg_story_size = force ? 0 : average_story_size.to_i
    saved_wish_heap_pts = force ? 0 : wish_heap_story_points.to_i

    self.trello_story_points_completed = story_points unless saved_story_pts > 0
    self.average_story_size = compute_average_story_size unless saved_avg_story_size > 0
    self.wish_heap_story_points = compute_wish_heap_points unless saved_wish_heap_pts > 0
  end
  # rubocop: enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # rubocop: disable Metrics/AbcSize
  def assign_computed_fields_for_current_sprint
    return unless current?
    self.trello_story_points_committed = compute_story_points_committed
    self.trello_story_points_completed = story_points
    self.average_story_size = compute_average_story_size
    self.backlog_story_points = board.backlog.story_points
    self.backlog_stories_count = board.backlog.stories.count
    self.wish_heap_stories_count = board.wish_heap.stories.count
    self.wish_heap_story_points = compute_wish_heap_points
  end
  # rubocop: enable Metrics/AbcSize

  def compute_story_points_committed
    # Commited story points should only be set programmatically at the beginning of
    # sprint. Otherwise scrum master will need to set manually.
    return story_points_committed unless story_points_committed.nil?
    board.story_points_committed if current? && age.days <= 2.days
  end

  # rubocop: disable Metrics/AbcSize
  def compute_wish_heap_points
    # wish_heap_points = backlog_story_points / backlog_stories_count * wish_heap_stories_count
    # If we have saved values available to calculate, calculate
    saved_backlog_pts = backlog_story_points.to_i
    saved_backlog_stories = backlog_stories_count.to_i
    saved_wish_heap_stories = wish_heap_stories_count.to_i

    if saved_backlog_pts > 0 && saved_backlog_stories > 0 && saved_wish_heap_stories > 0
      return (1.0 * saved_backlog_pts / saved_backlog_stories * wish_heap_stories_count).round
    end

    # If we're current, let the board try to compute
    board.estimate_wish_heap_points if current?
  end
  # rubocop: enable Metrics/AbcSize

  # rubocop: disable Metrics/AbcSize
  def compute_average_story_size
    return nil unless story_count > 0

    if current? && board.current_sprint.stories.present?
      board.current_sprint.story_points / board.current_sprint.stories.length
    else
      story_points / story_count
    end
  end
  # rubocop: enable Metrics/AbcSize

  #
  # Custom Validators
  #
  def name_is_valid
    valid = trello_name.present? || local_name.present?
    error_message = 'Name must be present'
    errors.add(:local_name, error_message) unless valid
  end

  def story_points_are_valid
    valid = local_story_points_completed.present? || trello_story_points_completed.present?
    error_message = 'Story points completed must be present'
    errors.add(:local_story_points_completed, error_message) unless valid
  end
end
