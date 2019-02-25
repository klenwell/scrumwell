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
    import = TrelloImport.create({ scrum_board_id: board.id, created_at: ancient_past })

    # Assume
    assert import.stuck?
    assert_not import.aborted?

    # Act
    import.abort_now

    # Assert
    assert_not import.stuck?
    assert import.aborted?
  end
end
