# Wraps trello-ruby gem.
# https://github.com/jeremytregunna/ruby-trello
class TrelloService
  attr_reader :me

  def self.user(name_or_id)
    Trello::Member.find(name_or_id)
  end

  def self.member(name_or_id)
    TrelloService.user(name_or_id)
  end

  def self.board(id)
    Rails.cache.fetch("trello_board/#{id}", expires_in: 5.minutes) do
      Trello::Board.find(id)
    end
  end

  def self.org(id)
    Rails.cache.fetch("trello_org/#{id}", expires_in: 1.minute) do
      Trello::Organization.find(id)
    end
  end

  def self.list(id)
    Rails.cache.fetch("trello_list/#{id}", expires_in: 1.minute) do
      Trello::List.find(id)
    end
  end

  def self.card(id)
    Rails.cache.fetch("trello_card/#{id}", expires_in: 1.minute) do
      Trello::Card.find(id)
    end
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
  rescue StandardError
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
    board.prefs['permissionLevel'] == 'public'
  end

  def org_board_map(org)
    board_hash = {}
    org.boards.each do |board|
      board_hash[board.name] = board.id
    end
    board_hash
  end
end
