class ScrumBacklog < ApplicationRecord
  belongs_to :scrum_project, optional: true

  attr_accessor :api

  after_initialize do |backlog|
    backlog.api = TrelloService.new
  end

  # Class Methods
  def self.scrummy_trello_board?(trello_board)
    # A scrummy board will contain these lists: wish heap, backlog, current
    board_list_names = trello_board.lists.map { |list| list.name.downcase.strip }
    p board_list_names
    return false unless board_list_names.include? 'wish heap'
    return false unless board_list_names.include? 'backlog'
    board_list_names.any? { |list_name| list_name.include? 'current' }
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
