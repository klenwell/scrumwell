class ScrumSprint < ApplicationRecord
  belongs_to :scrum_board
  has_many :user_stories, -> { order(trello_pos: :asc) }, as: :queue,
                                                          dependent: :destroy,
                                                          inverse_of: :queue

  attr_accessor :imported_from_trello

  alias_attribute :board, :scrum_board
  alias_attribute :stories, :user_stories

  before_save :reset_trello_fields, if: :imported_from_trello?
  before_save :assign_computed_fields

  validates :name, presence: true
  validates :started_on, presence: true
  validates :ended_on, presence: true
  validates :story_points_completed, presence: true
  validates :stories_count, presence: true

  #
  # Class Methods
  #
  def self.update_or_create_from_trello_list(scrum_board, trello_list)
    sprint = ScrumSprint.find_by(trello_list_id: trello_list.id)

    if sprint.present?
      sprint.imported_from_trello = true
      sprint.scrum_board_id = scrum_board.id
      update_from_trello_list(trello_list)
    else
      sprint = ScrumSprint.create_from_trello_list(scrum_board, trello_list)
    end

    sprint
  end

  def self.create_from_trello_list(scrum_board, trello_list)
    # Regex: https://stackoverflow.com/a/12858147/1093087
    name = trello_list.name.delete("^0-9")
    ends_on = Date.parse(name)
    starts_on = ends_on - ScrumBoard::DEFAULT_SPRINT_DURATION

    sprint = ScrumSprint.create!(scrum_board_id: scrum_board.id,
                                 trello_list_id: trello_list.id,
                                 trello_pos: trello_list.pos,
                                 name: name,
                                 started_on: starts_on,
                                 ended_on: ends_on,
                                 stories_count: 0,
                                 story_points_completed: 0,
                                 last_imported_at: Time.now.utc)
    sprint.imported_from_trello = true
    sprint.save_stories_from_trello_list(trello_list)
    sprint
  end

  def self.sprint_backlog_from_trello_list(scrum_board, trello_list)
    # Returns a temporary unsaved record from scrum backlog ("Current Sprint") column.
    backlog = ScrumSprint.new(scrum_board_id: scrum_board.id,
                              trello_list_id: trello_list.id,
                              trello_pos: trello_list.pos,
                              name: trello_list.name,
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
  def update_from_trello_list(trello_list=nil)
    trello_list ||= TrelloService.list(trello_list_id)
    return unless trello_list

    self.imported_from_trello = true
    self.trello_pos = trello_list.pos
    self.last_imported_at = Time.now.utc
    self.story_points_completed = 0
    self.stories_count = 0
    save!

    stories.destroy_all
    save_stories_from_trello_list(trello_list)
  end

  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
    end
    save!
  end

  def average_story_size
    return nil unless stories_count
    1.0 * story_points_completed / stories_count
  end

  def story_points
    stories ? stories.sum(&:points) : story_points_completed
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

  # private

  def imported_from_trello?
    @imported_from_trello == true
  end

  def reset_trello_fields
    # Need to reload stories to compute points accurately.
    # Reference: https://stackoverflow.com/a/29280034/1093087
    stories.reset
    self.stories_count = stories.length
    self.story_points_completed = stories.sum(&:points)
    self.wish_heap_story_points = compute_wish_heap_points
  end

  def assign_computed_fields
    assign_computed_fields_for_completed_sprint if over?
    assign_computed_fields_for_current_sprint if current?
  end

  def assign_computed_fields_for_completed_sprint
    self.average_velocity = board.average_velocity_for_sprint(self)
  end

  def assign_computed_fields_for_current_sprint
    self.story_points_committed = compute_story_points_committed
    self.backlog_story_points = board.backlog.story_points
    self.backlog_stories_count = board.backlog.stories.count
    self.wish_heap_stories_count = board.wish_heap.stories.count
    self.wish_heap_story_points = compute_wish_heap_points
  end

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
end
