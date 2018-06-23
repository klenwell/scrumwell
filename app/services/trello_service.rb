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
    @me = TrelloService.user('me')
  end

  def orgs
    @me.organizations
  end

  def public_orgs
    orgs.keep_if { |org| org_public?(org) }
  end

  def org_map
    org_hash = {}
    orgs.each do |org|
      org_hash[org.name] = org.id
    end
    org_hash
  end

  def org_prefs(org)
    path = format('/organizations/%s/prefs', org.id)
    response = @me.client.get(path)
    JSON.parse(response.body)
  rescue
    {}
  end

  def org_public?(org)
    return false if org.nil?
    org_prefs(org)['permissionLevel'] == 'public'
  end

  def boards
    @me.boards
  end

  def public_boards
    collected_boards = []
    boards.each do |board|
      collected_boards << board
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

  def board_public?(board)
    # Sometimes board.organization will return a 401 error when there is a board.
    # Maybe it's been deleted?
    org = board.organization rescue nil

    # If board is public, sure
    return true if board.prefs['permissionLevel'] == 'public'

    # If board permission tied to org
    return true if board.prefs['permissionLevel'] == 'org' && org_public?(org)

    # Any other cases?
    false

    is_public_board = board.prefs['permissionLevel'] == 'public'
  end

  def org_board_map(org)
    board_hash = {}
    org.boards.each do |board|
      board_hash[board.name] = board.id
    end
    board_hash
  end
end
