require 'test_helper'

class TrelloBoardTest < ActiveSupport::TestCase
  test "expects new trello board to have TrelloService api object" do
    board = TrelloBoard.new
    assert_instance_of TrelloService, board.api
  end

  test "expects to find board by trello api board id" do
    # Arrange
    scrum_board = trello_boards(:scrum)
    api_board = Trello::Board.new(id: scrum_board.trello_id)

    # Act
    board = TrelloBoard.by_api_board_or_create(api_board)

    # Assert
    assert_equal scrum_board, board
  end

  test "expects to create board by trello api board id" do
    # Arrange
    api_board = Trello::Board.new(id: 'trello-id')

    # Assume
    board_count_before = TrelloBoard.count

    # Act
    board = TrelloBoard.by_api_board_or_create(api_board)

    # Assert
    assert_equal api_board.id, board.trello_id
    assert_equal board_count_before + 1, TrelloBoard.count
  end
end
