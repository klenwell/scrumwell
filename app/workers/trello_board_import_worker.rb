class TrelloBoardImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0

  # rubocop: disable Metrics/AbcSize
  def perform(import_id)
    import = TrelloImport.find(import_id)
    board = import.board
    ImportLogger.info format("TrelloBoardImportWorker started: %s", import.id)

    import = board.update_from_trello(import)

    # Log Results
    board.reload
    if import.events.present?
      ImportLogger.info format("Imported %s events from %s to %s.", import.events.count,
                               import.events.first.occurred_at, import.events.last.occurred_at)
    end
    ImportLogger.info format("Created %s wip_logs.", board.wip_logs.count)
    ImportLogger.info format("Current Board Velocity: %s", board.current_velocity)
    ImportLogger.info format("TrelloBoardImportWorker succeeded: %s", import.id)
  rescue StandardError => e
    ImportLogger.error format("TrelloBoardImportWorker failed: %s", import_id)
    import.err_now(e) if import.present?
    raise e
  end
  # rubocop: enable Metrics/AbcSize
end
