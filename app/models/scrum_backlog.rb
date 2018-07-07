class ScrumBacklog < ApplicationRecord
  belongs_to :scrum_board
  has_many :user_stories, -> { order(trello_pos: :asc) }, as: :queue,
                                                          dependent: :destroy,
                                                          inverse_of: :queue

  alias_attribute :board, :scrum_board
  alias_attribute :stories, :user_stories

  #
  # Class Methods
  #
  def self.update_or_create_from_trello_list(scrum_board, trello_list)
    backlog = ScrumBacklog.find_by(trello_list_id: trello_list.id)

    if backlog.present?
      backlog.update_from_trello_list(trello_list)
      backlog.save_stories_from_trello_list(trello_list)
    else
      backlog = ScrumBacklog.create_from_trello_list(scrum_board, trello_list)
    end

    backlog
  end

  def self.create_from_trello_list(scrum_board, trello_list)
    backlog = ScrumBacklog.create(scrum_board_id: scrum_board.id,
                                  trello_list_id: trello_list.id,
                                  trello_pos: trello_list.pos,
                                  name: trello_list.name,
                                  last_pulled_at: Time.now.utc)
    backlog.save_stories_from_trello_list(trello_list)
    backlog
  end

  #
  # Instance Methods
  #
  def update_from_trello_list(trello_list)
    update(scrum_board_id: scrum_board.id,
           name: trello_list.name,
           trello_pos: trello_list.pos,
           last_pulled_at: Time.now.utc)
  end

  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
    end
  end

  def story_points
    stories.sum(&:points)
  end
end
