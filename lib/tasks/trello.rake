# rubocop: disable Metrics/BlockLength
namespace :trello do
  default_member = 'me'
  kwoss_org_id = '5129323d688a384c63007609'
  scrumwell_board_id = '5b26fe3ad86bfdbb5a8290b1'

  desc "Counts wish heap stories for given board"
  task :wish_heap, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    trello_board = TrelloService.board(args[:board_id])
    board = ScrumBoard.by_trello_board_or_create(trello_board)

    puts format("Board %s Wish Heap stories: %d", board.name, board.wish_heap.stories.length)
  end

  # rake trello:backlog
  desc "Counts story points in backlog info for given board"
  task :backlog, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])
    backlog = board.lists.find { |list| list.name.downcase.include? 'backlog' }
    byebug

    abort "Backlog list not found for board #{board.name}." unless backlog

    backlog_story_points = 0
    backlog.cards.each do |card|
      story_points = UserStory.story_points_from_card(card)
      backlog_story_points += story_points
      puts format('[%d] %s', story_points, card.name)
    end

    puts format("Backlog points for board %s: %d", board.name, backlog_story_points)
  end

  desc "Lists boards ids for given member"
  task :boards, [:member_name] => :environment do |_, args|
    args.with_defaults(member_name: default_member)

    member = TrelloService.user(args[:member_name])

    board_map = {}
    member.boards.each do |board|
      board_map[board.name] = board.id
    end

    pp board_map
    puts format("%s has %d boards", member.username, board_map.keys.count)
  end

  desc "Lists organization ids for given member"
  task :orgs, [:member_name] => :environment do |_, args|
    args.with_defaults(member_name: default_member)

    member = TrelloService.user(args[:member_name])

    org_map = {}
    member.organizations.each do |org|
      org_map[org.name] = org.id
    end

    pp org_map
    puts format("%s belongs to %d orgs", member.username, org_map.keys.count)
  end

  desc "Lists organization ids for kwoss org"
  task kwoss: :environment do |_|
    org = TrelloService.org(kwoss_org_id)

    board_map = {}
    org.boards.each do |board|
      board_map[board.name] = board.id
    end

    pp board_map
    puts format("%s org has %d boards", org.name, board_map.keys.count)
  end

  desc "Lists board's lists"
  task :lists, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])

    board_lists_map = { board.name => [] }
    board.lists.each do |list|
      list_data = {
        name: list.name,
        pos: list.pos,
        stories: list.cards.count
      }
      board_lists_map[board.name] << list_data
    end

    pp board_lists_map
    puts format("%s board has %d lists.", board.name, board_lists_map[board.name].count)
  end
end
# rubocop: enable Metrics/BlockLength
