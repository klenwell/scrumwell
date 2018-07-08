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

  #
  # Instance Methods
  #
  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
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

  def story_points
    stories.sum(&:points)
  end

  # private

  # rubocop: disable Metrics/AbcSize
  def set_computed_fields
    # Need to reload stories to compute points accurately.
    # Reference: https://stackoverflow.com/a/29280034/1093087
    stories.reset

    # These values can be computed even if the sprint is over when values are empty.
    if over?
      self.story_points_completed = story_points if story_points_completed.nil?
      self.average_velocity = board.average_velocity_for_sprint(self) if average_velocity.nil?
      self.average_story_size = story_points / stories.count if average_story_size.nil?
    end

    # Proceed to compute values below only if sprint is current
    return unless current?

    self.story_points_committed = board.story_points_committed
    self.story_points_completed = story_points
    self.average_velocity = board.average_velocity
    self.average_story_size = board.compute_average_story_size
    self.backlog_story_points = board.backlog.story_points
    self.backlog_stories_count = board.backlog.story_points
    self.wish_heap_stories_count = board.wish_heap.stories.count
    self.wish_heap_story_points = board.estimate_wish_heap_points
  end
  # rubocop: enable Metrics/AbcSize

  def compute_average_story_size
    return nil unless stories.count
    story_points / stories.count
  end
end
