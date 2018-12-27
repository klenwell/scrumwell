# rubocop: disable Metrics/BlockLength
namespace :scrum do
  # rake scrum:import_board[5b26fe3ad86bfdbb5a8290b1]
  desc "Imports board and reconstructs its history from Trello events."
  task :import_board, [:trello_board_id] => :environment do |_, args|
    # Parse args
    trello_board_id = args[:trello_board_id]

    # Delete existing board
    board = ScrumBoard.find_by(trello_board_id: trello_board_id)
    if board.present?
      LogService.rake format("Destroying existing board: %s", board.name)
      board.destroy
    end
    `rake log:clear` if Rails.env.development?

    # Find Trello board
    trello_board = TrelloService.board(trello_board_id)
    LogService.rake format("Importing board: %s", trello_board.name)

    # Create scrum board from Trello board
    board = ScrumBoard.import_from_trello(trello_board)

    # Stdout
    trello_api_calls = `grep httplog log/development.log | grep "api.trello.com" | wc -l`
    board.queues.each { |q| puts q.to_stdout }
    LogService.rake format("Created %s events.", board.events.count)
    LogService.rake format("Created %s wip_logs.", board.wip_logs.count)
    LogService.rake format("Current Board Velocity: %s", board.current_velocity)
    LogService.rake format("Trello API calls: %s", trello_api_calls)
  end

  # rake scrum:update_board[:id]
  desc "Imports board and reconstructs its history from Trello events."
  task :update_board, [:scrum_board_id] => :environment do |_, args|
    # Arrange
    board_id = args[:scrum_board_id]
    board = ScrumBoard.find(board_id)
    LogService.rake format("Updating board %s (last update: %s)",
                           board.name,
                           board.last_event.occurred_at)
    `rake log:clear` if Rails.env.development?

    # Update scrum board from Trello board
    import = board.update_from_trello
    board.reload

    # Report
    trello_api_calls = `grep httplog log/development.log | grep "api.trello.com" | wc -l`
    LogService.rake format("Created %s wip_logs.", board.wip_logs.count)
    LogService.rake format("Current Board Velocity: %s", board.current_velocity)
    LogService.rake format("Trello API calls: %s", trello_api_calls)
    if import.events.present?
      LogService.rake format("Imported %s events from %s to %s.", import.events.count,
                             import.events.first.occurred_at, import.events.last.occurred_at)
    end
  end

  # rake scrum:rebuild_wip_log[Scrumwell]
  desc "Rebuild scrum board's Work-in-Progress from scratch using events."
  task :rebuild_wip_log, [:board_name] => :environment do |_, args|
    board = ScrumBoard.find_by(name: args[:board_name])
    board.wip_logs.destroy_all

    `rake log:clear` if Rails.env.development?

    LogService.rake format("Rebuilding WipLog for board: %s", board.name)
    board.build_wip_log_from_scratch
    board.reload

    LogService.rake format("WIP logs for board %s: %s", board.name, board.wip_logs.count)
    LogService.rake format("Current Board Velocity: %s", board.current_velocity)
  end

  # rake scrum:sandbox
  desc "Test saving a trello card's raw data to a scrum story"
  task sandbox: :environment do |_|
    card_id = '5b5dfe72d8fe85b05c24e906'
    trello_card = TrelloService.card(card_id)

    story = ScrumStory.new(trello_data: trello_card)
    story.save!

    byebug
  end
end
# rubocop: enable Metrics/BlockLength
