# rubocop: disable Metrics/BlockLength
namespace :scrum do
  # rake scrum:import_board[5b26fe3ad86bfdbb5a8290b1]
  desc "Imports board and reconstructs its history from Trello events."
  task :import_board, [:trello_board_id] => :environment do |_, args|
    trello_board_id = args[:trello_board_id]
    board = ScrumBoard.find_by(trello_board_id: trello_board_id)
    if board.present?
      puts format("Destroying existing board: %s", board.name)
      board.destroy
    end

    `rake log:clear` if Rails.env.development?

    trello_board = TrelloService.board(trello_board_id)
    puts format("Importing board: %s", trello_board.name)

    board = ScrumBoard.reconstruct_from_trello_board_actions(trello_board)
    board.build_wip_log_from_scratch

    # Stdout
    trello_api_calls = `grep httplog log/development.log | grep "api.trello.com" | wc -l`
    puts board
    board.queues.each { |q| puts q.to_stdout }
    puts format("Created %s events.", board.events.count)
    puts format("Created %s wip_logs.", board.wip_logs.count)
    puts format("Current Board Velocity: %s", board.current_velocity)
    puts format("Trello API calls: %s", trello_api_calls)
  end

  # rake scrum:reconstruct_board[5b26fe3ad86bfdbb5a8290b1]
  desc "Reconstructs scrum board's full history from Trello board's actions"
  task :reconstruct_board, [:board_id] => :environment do |_, args|
    ScrumBoard.destroy_all
    ScrumEvent.destroy_all

    `rake log:clear` if Rails.env.development?

    trello_board = TrelloService.board(args[:board_id])
    puts format("Importing board: %s", trello_board.name)

    board = ScrumBoard.reconstruct_from_trello_board_actions(trello_board)

    board.queues.each do |queue|
      puts format("Queue %s: %s points", queue.name, queue.points)
    end

    trello_api_calls = `grep httplog log/development.log | grep "api.trello.com" | wc -l`
    puts format("Created %s queues.", ScrumQueue.count)
    puts format("Created %s events.", ScrumEvent.count)
    puts format("Trello API calls: %s", trello_api_calls)

    byebug if board
  end

  # rake scrum:rebuild_wip_log[Scrumwell]
  desc "Rebuild scrum board's Work-in-Progress from scratch using events."
  task :rebuild_wip_log, [:board_name] => :environment do |_, args|
    WipLog.destroy_all

    `rake log:clear` if Rails.env.development?

    board = ScrumBoard.find_by(name: args[:board_name])
    puts format("Rebuilding WipLog for board: %s", board.name)

    board.build_wip_log_from_scratch
    board.reload

    puts format("WIP logs for board %s: %s", board.name, board.wip_logs.count)
    puts format("Current Board Velocity: %s", board.current_velocity)
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
