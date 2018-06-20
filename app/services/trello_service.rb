class TrelloService
  def self.user(name)
    Trello::Member.find(name)
  end

  def self.board(id)
    Trello::Board.find(id)
  end
end
