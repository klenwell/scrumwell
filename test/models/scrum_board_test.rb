require 'test_helper'

class ScrumBoardTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects trello board to be identified as scrummy" do
    # Arrange
    list_names = ['wish heap', 'backlog', 'current']
    scrummy_board = mock_trello_board(id: 'scrummy-board', list_names: list_names)

    # Act
    is_scrummy = ScrumBoard.scrummy_trello_board?(scrummy_board)

    # Assert
    assert is_scrummy
  end

  test "expects trello board NOT to be identified as scrummy" do
    # Arrange
    list_names = ['Todo', 'Doing', 'Done']
    unscrummy_board = mock_trello_board(id: 'non-scrummy-board', list_names: list_names)

    # Act
    is_scrummy = ScrumBoard.scrummy_trello_board?(unscrummy_board)

    # Assert
    assert_not is_scrummy
  end

  test "expects to find scrum board by trello board id" do
    # Arrange
    existing_board = scrum_boards(:scrummy)
    trello_board = mock_trello_board(id: existing_board.trello_board_id)

    # Act
    board = ScrumBoard.by_trello_board_or_create(trello_board)

    # Assert
    assert_equal existing_board, board
  end

  test "expects to create scrum board by trello board id" do
    # Arrange
    trello_board = mock_trello_board

    # Assume
    scrum_board_count_before = ScrumBoard.count

    # Act
    scrum_board = ScrumBoard.by_trello_board_or_create(trello_board)
    scrum_board.save!

    # Assert
    assert_equal trello_board.id, scrum_board.trello_board_id
    assert_equal scrum_board_count_before + 1, ScrumBoard.count
  end

  test "expects scrum board with invalid trello url to be invalid" do
    # Arrange
    trello_board = mock_trello_board

    # Act
    scrum_board = ScrumBoard.new(trello_board_id: trello_board.id,
                                 name: trello_board.name,
                                 trello_url: 'https://asana.com/scrummy-board')

    # Assert
    assert_not scrum_board.valid?
    assert_equal ["must be valid Trello url"], scrum_board.errors.messages[:trello_url]
  end
end
