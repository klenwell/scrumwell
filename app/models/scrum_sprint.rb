class ScrumSprint < ApplicationRecord
  belongs_to :scrum_board
  has_many :user_stories, -> { order(trello_pos: :asc) }, as: :queue,
                                                          dependent: :destroy,
                                                          inverse_of: :queue

  alias_attribute :board, :scrum_board
  alias_attribute :stories, :user_stories

  before_save :set_computed_fields, if: proc { id.present? }

  #
  # Class Methods
  #
  def self.create_from_trello_list(scrum_board, trello_list)
    # https://stackoverflow.com/a/12858147/1093087
    name = trello_list.name.delete("^0-9")
    ends_on = Date.parse(name)
    starts_on = ends_on - ScrumBoard::DEFAULT_SPRINT_DURATION

    sprint = ScrumSprint.create(scrum_board_id: scrum_board.id,
                                trello_list_id: trello_list.id,
                                trello_pos: trello_list.pos,
                                name: name,
                                started_on: starts_on,
                                ended_on: ends_on,
                                last_pulled_at: Time.now.utc)
    sprint.save_stories_from_trello_list(trello_list)

    # Touch to force compute fields to be saved
    sprint.update(last_pulled_at: Time.now.utc)

    sprint
  end

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

  def self.sprint_backlog_from_trello_list(scrum_board, trello_list)
    # Returns a temporary unsaved record from scrum backlog ("Current Sprint") column.
    backlog = ScrumSprint.new(scrum_board_id: scrum_board.id,
                              trello_list_id: trello_list.id,
                              trello_pos: trello_list.pos,
                              name: trello_list.name,
                              last_pulled_at: Time.now.utc)

    # Attach cards
    trello_list.cards.each do |card|
      next unless UserStory.user_story_card?(card)
      backlog.stories << UserStory.new_from_trello_card(card)
    end

    backlog
  end

  #
  # Instance Methods
  #
  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
    end
  end

  def recompute!
    # Force an update to run set_computed_fields callbacks.
    update(updated_at: Time.zone.now)
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

  def story_points
    stories.sum(&:points)
  end

  def age
    Time.zone.today - started_on
  end

  # private

  def set_computed_fields
    # Need to reload stories to compute points accurately.
    # Reference: https://stackoverflow.com/a/29280034/1093087
    stories.reset
    set_computed_fields_for_completed_sprint
    set_computed_fields_for_current_sprint
  end

  def set_computed_fields_for_completed_sprint
    # Notice most only get set if they're still nil.
    return unless over?
    self.story_points_completed = story_points if story_points_completed.nil?
    self.average_velocity = board.average_velocity_for_sprint(self) if average_velocity.nil?
    self.average_story_size = compute_average_story_size if average_story_size.nil?
  end

  # rubocop: disable Metrics/AbcSize
  def set_computed_fields_for_current_sprint
    return unless current?
    self.story_points_committed = compute_story_points_committed
    self.story_points_completed = story_points
    self.average_story_size = compute_average_story_size
    self.backlog_story_points = board.backlog.story_points
    self.backlog_stories_count = board.backlog.stories.count
    self.wish_heap_stories_count = board.wish_heap.stories.count
    self.wish_heap_story_points = board.estimate_wish_heap_points
  end
  # rubocop: enable Metrics/AbcSize

  def compute_story_points_committed
    # Commited story points should only be set programmatically at the beginning of
    # sprint. Otherwise scrum master will need to set manually.
    return story_points_committed unless story_points_committed.nil?
    board.story_points_committed if current? && age.days <= 2.days
  end

  def compute_wish_heap_points
    # Commited story points should only be set programmatically at the beginning of
    # sprint. Otherwise scrum master will need to set manually.
    return wish_heap_story_points unless wish_heap_story_points.nil?
    board.estimate_wish_heap_points if current? && age.days <= 2.days
  end

  # rubocop: disable Metrics/AbcSize
  def compute_average_story_size
    return nil unless stories.count

    if current? && board.current_sprint.stories.present?
      board.current_sprint.story_points / board.current_sprint.stories.length
    else
      story_points / stories.length
    end
  end
  # rubocop: enable Metrics/AbcSize
end
