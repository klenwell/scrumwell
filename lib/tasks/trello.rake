# rubocop: disable Metrics/BlockLength
namespace :trello do
  default_member = 'me'
  kwoss_org_id = '5129323d688a384c63007609'
  scrumwell_board_id = '5b26fe3ad86bfdbb5a8290b1'

  # rake trello:import_board[:id]
  desc "Imports most recent board actions from Trello to update board."
  task :import_board, [:scrum_board_id] => :environment do |_, args|
    # Parse args
    scrum_board_id = args[:scrum_board_id]

    # Find board
    board = ScrumBoard.find_by(id: scrum_board_id)
    abort "Board not found." if board.blank?

    # Compare Scrum::BoardsController#import and TrelloBoardImportWorker#perform
    import = TrelloImport.create(scrum_board: board)
    TrelloBoardImportWorker.new.perform(import.id)
  end

  # rake trello:reimport_board[5b26fe3ad86bfdbb5a8290b1]
  desc "Fully reconstructs a Trello board by importing its actions."
  task :reimport_board, [:trello_board_id] => :environment do |_, args|
    # Parse args
    trello_board_id = args[:trello_board_id]

    # Delete existing board
    # Note: this is slow for large boards. It's quicker just to nuke the database
    # with rake db:schema:load (but that will take everything with it.)
    board = ScrumBoard.find_by(trello_board_id: trello_board_id)
    if board.present?
      ImportLogger.info format("Destroying existing board: %s", board.name)
      board.destroy
    end
    `rake log:clear` if Rails.env.development?

    # Import Trello board
    import = TrelloImport.import_full_board(trello_board_id)

    # Stdout
    trello_api_calls = `grep httplog log/development.log | grep "api.trello.com" | wc -l`
    import.board.queues.each { |q| puts q.to_stdout }
    ImportLogger.info format("Created %s events.", import.board.events.count)
    ImportLogger.info format("Created %s wip_logs.", import.board.wip_logs.count)
    ImportLogger.info format("Current Board Velocity: %s", import.board.current_velocity)
    ImportLogger.info format("Trello API calls: %s", trello_api_calls)
  end

  # rake trello:wish_heap[5b26fe3ad86bfdbb5a8290b1]
  desc "Counts wish heap stories for given board"
  task :wish_heap, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])
    wish_heap = board.lists.find { |list| list.name.downcase.include? 'wish heap' }

    ImportLogger.info(
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
      ImportLogger.info format('[%d] %s', story_points, card.name)
    end

    ImportLogger.info format("Backlog points for board %s: %d", board.name, backlog_story_points)
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

    ImportLogger.info board_map
    ImportLogger.info format("%s has %d boards", member.username, board_map.keys.count)
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

    ImportLogger.info org_map
    ImportLogger.info format("%s belongs to %d orgs", member.username, org_map.keys.count)
  end

  desc "Lists organization ids for kwoss org"
  task kwoss: :environment do |_|
    org = TrelloService.org(kwoss_org_id)

    board_map = {}
    org.boards.each do |board|
      board_map[board.name] = board.id
    end

    ImportLogger.info board_map
    ImportLogger.info format("%s org has %d boards", org.name, board_map.keys.count)
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

    ImportLogger.info board_lists_map
    ImportLogger.info format("%s board has %d lists.",
                             board.name,
                             board_lists_map[board.name].count)
  end
end
# rubocop: enable Metrics/BlockLength
