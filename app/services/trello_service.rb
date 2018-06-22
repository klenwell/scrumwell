class TrelloService
  attr_reader :me

  def self.user(name)
    Trello::Member.find(name)
  end

  def self.board(id)
    Trello::Board.find(id)
  end

  def self.org(id)
    Trello::Organization.find(id)
  end

  def initialize
    @me = TrelloService::user('me')
  end

  def orgs
    @me.organizations
  end

  def org_map
    org_hash = {}
    orgs.each do |org|
      org_hash[org.name] = org.id
    end
    org_hash
  end

  def boards
    @me.boards
  end

  def public_boards
    collected_boards = []
    boards.each do |board|
      if board.prefs['permissionLevel'] == 'public'
        collected_boards << board
      # ruby-trello gem doesn't seem to provide org permission data so we'll just
      # treat as public for now.
      # See https://stackoverflow.com/questions/50979870
      elsif board.prefs['permissionLevel'] == 'org'
        collected_boards << board
      end
    end
    collected_boards
  end

  def board_map
    board_hash = {}
    @me.boards.each do |board|
      board_hash[board.name] = board.id
    end
    board_hash
  end

  def org_board_map(org)
    board_hash = {}
    org.boards.each do |board|
      board_hash[board.name] = board.id
    end
    board_hash
  end
end
