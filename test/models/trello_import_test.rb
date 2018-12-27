require 'test_helper'

class TrelloImportTest < ActiveSupport::TestCase
  test "expects to create new import" do
    # Arrange
    board = scrum_boards(:scrummy)
    params = {
      scrum_board_id: board.id
    }

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
    params = {
      scrum_board_id: board.id
    }
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
end
