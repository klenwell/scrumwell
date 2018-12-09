# rubocop: disable Metrics/BlockLength
namespace :trello do
  default_member = 'me'
  kwoss_org_id = '5129323d688a384c63007609'
  scrumwell_board_id = '5b26fe3ad86bfdbb5a8290b1'

  # rake trello:wish_heap[5b26fe3ad86bfdbb5a8290b1]
  desc "Counts wish heap stories for given board"
  task :wish_heap, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])
    wish_heap = board.lists.find { |list| list.name.downcase.include? 'wish heap' }

    LogService.rake(
      format("Board %s Wish Heap stories: %d", board.name, wish_heap.cards.length)
    )
  end

  # rake trello:backlog[5b26fe3ad86bfdbb5a8290b1]
  desc "Counts story points in backlog info for given board"
  task :backlog, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])
    backlog = board.lists.find { |list| list.name.downcase.include? 'backlog' }

    abort "Backlog list not found for board #{board.name}." unless backlog

    backlog_story_points = 0
    backlog.cards.each do |card|
      story_points = ScrumStory.points_from_card(card)
      backlog_story_points += story_points
      LogService.rake format('[%d] %s', story_points, card.name)
    end

    LogService.rake format("Backlog points for board %s: %d", board.name, backlog_story_points)
  end

  # rake trello:boards[scrumwell]
  desc "Lists boards ids for given member"
  task :boards, [:member_name] => :environment do |_, args|
    args.with_defaults(member_name: default_member)

    member = TrelloService.user(args[:member_name])

    board_map = {}
    member.boards.each do |board|
      board_map[board.name] = board.id
    end

    LogService.pretty board_map
    LogService.rake format("%s has %d boards", member.username, board_map.keys.count)
  end

  # rake trello:orgs[scrumwell]
  desc "Lists organization ids for given member"
  task :orgs, [:member_name] => :environment do |_, args|
    args.with_defaults(member_name: default_member)

    member = TrelloService.user(args[:member_name])

    org_map = {}
    member.organizations.each do |org|
      org_map[org.name] = org.id
    end

    LogService.pretty org_map
    LogService.rake format("%s belongs to %d orgs", member.username, org_map.keys.count)
  end

  desc "Lists organization ids for kwoss org"
  task kwoss: :environment do |_|
    org = TrelloService.org(kwoss_org_id)

    board_map = {}
    org.boards.each do |board|
      board_map[board.name] = board.id
    end

    LogService.pretty board_map
    LogService.rake format("%s org has %d boards", org.name, board_map.keys.count)
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

    LogService.pretty board_lists_map
    LogService.rake format("%s board has %d lists.", board.name, board_lists_map[board.name].count)
  end
end
# rubocop: enable Metrics/BlockLength
