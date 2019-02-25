require 'test_helper'

class Trello::ImportControllerTest < ActionDispatch::IntegrationTest
  test "expects import to be aborted" do
    # Arrange
    board = scrum_boards(:scrummy)
    ancient_past = Time.zone.now - (TrelloImport::STALLED_IMPORT_TIME_LIMIT + 1)
    import = TrelloImport.create({ scrum_board_id: board.id, created_at: ancient_past })
    login_as(email: 'testing@gmail.com', scrum_master: true)

    # Assume
    assert import.stuck?

    # Act
    patch trello_import_abort_url(import)
    import.reload

    # Assert
    assert_redirected_to trello_import_url(import)
    assert_not import.stuck?
    assert import.aborted?
  end

  test "expects import not to be aborted if not stuck" do
    # Arrange
    board = scrum_boards(:scrummy)
    import = TrelloImport.create({ scrum_board_id: board.id })
    login_as(email: 'testing@gmail.com', scrum_master: true)

    # Assume
    assert_not import.stuck?

    # Act
    patch trello_import_abort_url(import)
    import.reload

    # Assert
    assert_redirected_to trello_import_url(import)
    assert_not import.stuck?
    assert_not import.aborted?
  end
end
