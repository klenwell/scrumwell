class TrelloBoard < ApplicationRecord
  belongs_to :scrum_project, optional: true

  attr_accessor :api

  after_initialize do |board|
    board.api = TrelloService.new
  end

  def self.active
    api = TrelloService.new
    active_boards = api.public_boards.map do |public_board|
      TrelloBoard.by_api_board_or_create(public_board)
    end
    active_boards
  end

  def self.by_api_board_or_create(api_board)
    existing_board = TrelloBoard.find_by(trello_id: api_board.id)
    return existing_board if existing_board
    TrelloBoard.create!(trello_id: api_board.id)
  end

  # Instance Methods
  # Live board data from Trello API
  def live
    api.board(trello_id)
  end
end
