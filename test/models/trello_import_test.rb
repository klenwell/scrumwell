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
    assert imports_before + 1, TrelloImport.count
  end
end
