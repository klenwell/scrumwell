class ScrumEvent < ApplicationRecord
  belongs_to :scrum_board

  def self.from_trello_board_event(board, trello_action)
    puts format('[%s] (%s) %s', trello_action.date, board.name, trello_action.type)
    ScrumEvent.new
  end

  #
  # Instance Methods
  #
  def creates_queue?; end

  def creates_story?; end

  def moves_story?; end

  def changes_story_status?; end
end
