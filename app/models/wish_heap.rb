#
# A WishHeap is another Trello list like ScrumSprint.
#
class WishHeap < ApplicationRecord
  belongs_to :scrum_board
  has_many :user_stories, -> { order(trello_pos: :asc) }, foreign_key: :scrum_sprint_id,
                                                          dependent: :destroy

  alias_attribute :board, :scrum_board
  alias_attribute :stories, :user_stories

  #
  # Class Methods
  #
  def self.create_from_trello_list(scrum_board, trello_list)
    wish_heap = WishHeap.create(scrum_board_id: scrum_board.id,
                                trello_list_id: trello_list.id,
                                trello_pos: trello_list.pos,
                                name: trello_list.name,
                                last_pulled_at: Time.now.utc)
    wish_heap.save_stories_from_trello_list(trello_list)
    wish_heap
  end

  def self.update_or_create_from_trello_list(scrum_board, trello_list)
    wish_heap = WishHeap.find_by(trello_list_id: trello_list.id)

    if wish_heap.present?
      wish_heap.scrum_board_id = scrum_board.id
      wish_heap.name = trello_list.name
      wish_heap.trello_pos = trello_list.pos
      wish_heap.last_pulled_at = Time.now.utc
      wish_heap.save!
      wish_heap.save_stories_from_trello_list(trello_list)
    else
      wish_heap = WishHeap.create_from_trello_list(scrum_board, trello_list)
    end

    wish_heap
  end

  #
  # Instance Methods
  #
  def save_stories_from_trello_list(trello_list)
    trello_list.cards.each do |card|
      UserStory.update_or_create_from_trello_card(self, card) if UserStory.user_story_card?(card)
    end
  end
end
