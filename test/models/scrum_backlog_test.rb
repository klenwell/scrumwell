require 'test_helper'

class ScrumBacklogTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects trello board to be identified as scrummy" do
    # Arrange
    list_names = ['wish heap', 'backlog', 'current']
    scrummy_board = mock_trello_board(id: 'scrummy-board', list_names: list_names)

    # Act
    is_scrummy = ScrumBacklog.scrummy_trello_board?(scrummy_board)

    # Assert
    assert is_scrummy
  end

  test "expects trello board NOT to be identified as scrummy" do
    # Arrange
    list_names = ['Todo', 'Doing', 'Done']
    unscrummy_board = mock_trello_board(id: 'non-scrummy-board', list_names: list_names)

    # Act
    is_scrummy = ScrumBacklog.scrummy_trello_board?(unscrummy_board)

    # Assert
    assert_not is_scrummy
  end

  test "expects to find backlog by trello board id" do
    # Arrange
    existing_backlog = scrum_backlogs(:scrummy)
    trello_board = mock_trello_board(id: existing_backlog.trello_board_id)

    # Act
    backlog = ScrumBacklog.by_trello_board_or_new(trello_board)

    # Assert
    assert_equal existing_backlog, backlog
  end

  test "expects to create backlog by trello board id" do
    # Arrange
    trello_board = mock_trello_board

    # Assume
    backlog_count_before = ScrumBacklog.count

    # Act
    backlog = ScrumBacklog.by_trello_board_or_new(trello_board)
    backlog.save!

    # Assert
    assert_equal trello_board.id, backlog.trello_board_id
    assert_equal backlog_count_before + 1, ScrumBacklog.count
  end
end
