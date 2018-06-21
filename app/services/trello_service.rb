class TrelloService
  def self.user(name)
    Trello::Member.find(name)
  end

  def self.board(id)
    Trello::Board.find(id)
  end

  def self.org(id)
    Trello::Organization.find(id)
  end
end
