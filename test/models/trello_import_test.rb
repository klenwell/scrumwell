require 'test_helper'

class TrelloImportTest < ActiveSupport::TestCase
  test "expects to create new import" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = { scrum_board_id: board.id }

    # Assume
    imports_before = TrelloImport.count

    # Act
    trello_import = TrelloImport.create(params)

    # Assert
    assert_not trello_import.complete?
    assert_equal 'in-progress', trello_import.status
    assert imports_before + 1, TrelloImport.count
  end

  test "expects import status to be complete" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = { scrum_board_id: board.id }
    trello_import = TrelloImport.create(params)

    # Assume
    assert_equal 'in-progress', trello_import.status
    assert_nil trello_import.ended_at

    # Act
    trello_import.end_now

    # Assert
    assert trello_import.complete?
    assert_not_nil trello_import.ended_at
    assert_equal 'complete', trello_import.status
  end

  test "expects import to have erred" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = { scrum_board_id: board.id }
    trello_import = TrelloImport.create(params)
    import_error = ArgumentError.new('A test error.')

    # Assume
    assert_equal 'in-progress', trello_import.status
    assert_nil trello_import.ended_at

    # Act
    trello_import.err_now(import_error)

    # Assert
    assert trello_import.complete?
    assert trello_import.erred?
    assert_equal 'error', trello_import.status
    assert_equal 'A test error.', trello_import.error
  end

  test "expects a board to only allow one import at a time" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = { scrum_board_id: board.id }
    first_import = TrelloImport.create(params)

    # Assume
    assert_equal 'in-progress', first_import.status
    imports_before = TrelloImport.count

    # Act
    second_import = TrelloImport.create(params)

    # Assert
    assert_not second_import.persisted?
    assert imports_before, TrelloImport.count
    assert_equal 'Scrum board import already in progress',
                 second_import.errors.full_messages.to_sentence
  end

  test "expects import to be stuck" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = { scrum_board_id: board.id }
    import = TrelloImport.create(params)
    time_past = TrelloImport::STALLED_IMPORT_TIME_LIMIT + 1

    # Assume
    assert_equal 'in-progress', import.status

    # Act
    import.update(created_at: Time.zone.now - time_past)

    # Assert
    assert import.stuck?
    assert_equal 'in-progress', import.status
  end

  test "expects import to be aborted" do
    # Arrange
    board = scrum_boards(:scrummy)
    ancient_past = Time.zone.now - (TrelloImport::STALLED_IMPORT_TIME_LIMIT + 1)
    import = TrelloImport.create(scrum_board_id: board.id, created_at: ancient_past)

    # Assume
    assert import.stuck?
    assert_not import.aborted?

    # Act
    import.abort_now

    # Assert
    assert_not import.stuck?
    assert import.aborted?
  end

  test "expects to log trello action when there is an error during full board import" do
    # Arrange
    trello_board_id = 'foo'
    scrum_board = scrum_boards(:scrummy)
    trello_board = MockTrelloBoard.scrummy
    trello_list = MockTrelloList.new(name: 'Whatever')
    trello_action = MockTrelloAction.new(id: 'ABC123')
    import_error = StandardError.new('testing')

    TrelloService.stubs(:board).returns(trello_board)
    ScrumBoard.stubs(:find_or_create_by_trello_board).returns(scrum_board)
    TrelloImport.any_instance.stubs(:import_board_lists).returns([trello_list])
    ScrumBoard.any_instance.stubs(:latest_trello_actions).returns([trello_action])
    ScrumEvent.stubs(:create_from_trello_import).raises(import_error)

    # Assume
    expect_error_message = format("%s: %s", trello_action, import_error)
    ImportLogger.expects(:error).with(expect_error_message).once

    # Act
    import = TrelloImport.import_full_board(trello_board_id)

    # Assert
    assert_equal scrum_board, import.board
  end
end
