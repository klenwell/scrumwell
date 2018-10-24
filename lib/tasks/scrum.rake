namespace :scrum do
  # rake scrum:reconstruct_board[5b26fe3ad86bfdbb5a8290b1]
  desc "Reconstructs scrum board's full history from Trello board's actions"
  task :reconstruct_board, [:board_id] => :environment do |_, args|
    ScrumBoard.destroy_all
    ScrumEvent.destroy_all

    trello_board = TrelloService.board(args[:board_id])
    puts format("Importing board: %s", trello_board.name)

    ScrumBoard.reconstruct_from_trello_board_actions(trello_board)

    puts format("Created %s queues.", ScrumQueue.count)
    puts format("Created %s events.", ScrumEvent.count)
    byebug
  end
end
