class ScrumBacklog < ApplicationRecord
  belongs_to :scrum_project, optional: true

  attr_accessor :api

  after_initialize do |backlog|
    backlog.api = TrelloService.new
  end

  def self.active_boards
    api = TrelloService.new
    active_boards = api.public_boards.map do |public_board|
      TrelloBoard.by_trello_board_or_create(public_board)
    end
    active_boards
  end

  def self.by_trello_board_or_create(api_board)
    existing_scrumlog = ScrumBacklog.find_by(trello_board_id: api_board.id)
    return existing_scrumlog if existing_scrumlog
    ScrumBacklog.create!(trello_board_id: api_board.id)
  end

  # Instance Methods
  # Live board data from Trello API
  def live_board
    api.board(trello_id)
  end
end
