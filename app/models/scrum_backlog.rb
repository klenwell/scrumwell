class ScrumBacklog < ApplicationRecord
  attr_accessor :api

  after_initialize do |backlog|
    backlog.api = TrelloService.new
  end

  # Class Methods
  def self.scrummy_trello_board?(trello_board)
    # A scrummy board will contain these lists: wish heap, backlog, current
    scrummy_list_names = ['wish heap', 'backlog', 'current']
    board_list_names = trello_board.lists.map { |list| list.name.downcase.strip }

    scrummy_list_names.each do |required_name|
      return false unless board_list_names.any? { |list_name| list_name.include? required_name }
    end

    true
  end

  def self.by_trello_board_or_new(trello_board)
    backlog = ScrumBacklog.find_by(trello_board_id: trello_board.id)

    if backlog
      backlog.trello_url = trello_board.url
      backlog.last_board_activity_at = trello_board.last_activity_date
      backlog.last_pulled_at = Time.now.utc
    else
      backlog = ScrumBacklog.new(trello_board_id: trello_board.id,
                                 trello_url: trello_board.url,
                                 name: trello_board.name,
                                 last_board_activity_at: trello_board.last_activity_date,
                                 last_pulled_at: Time.now.utc)
    end

    backlog
  end

  # Instance Methods
  # Live board data from Trello API
  def live_board
    api.board(trello_id)
  end
end
