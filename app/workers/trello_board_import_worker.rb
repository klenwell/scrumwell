class TrelloBoardImportWorker
  include Sidekiq::Worker

  def perform(trello_board_id)
    board = ScrumBoard.find_by(trello_board_id: trello_board_id)

    board = if board.present?
              update_existing_board(board)
            else
              import_new_board(trello_board_id)
            end

    # Log Results
    LogService.log format("Created %s wip_logs.", board.wip_logs.count)
    LogService.log format("Current Board Velocity: %s", board.current_velocity)
  end

  private

  def import_new_board(trello_board_id)
    # This method echoes rake scrum:import_board
    # Connect to Trello API service.
    trello_board = TrelloService.board(trello_board_id)
    LogService.log format("Importing board: %s", trello_board.name)

    # Create scrum board from Trello board
    board = ScrumBoard.import_from_trello(trello_board)

    # Log Results
    LogService.log format("%s  Trello board import complete.", board.name)
    LogService.log format("Created %s events.", board.events.count)

    board
  end

  # rubocop: disable Metrics/AbcSize
  def update_existing_board(board)
    # This method echoes rake scrum:update_board
    LogService.log format("Updating board %s (last update: %s)",
                          board.name,
                          board.last_event.occurred_at)

    # Update scrum board from Trello board
    import = board.update_from_trello
    board.reload

    # Log Results
    if import.events.present?
      LogService.rake format("Imported %s events from %s to %s.", import.events.count,
                             import.events.first.occurred_at, import.events.last.occurred_at)
    end

    board
  end
  # rubocop: enable Metrics/AbcSize
end
