namespace :scrum do
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
