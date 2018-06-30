require 'test_helper'

class ScrumBacklogTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects trello board to be identified as scrummy" do
    # Arrange
    scrummy_board = Trello::Board.new(id: 'scrummy-board')
    lists = ['wish heap', 'backlog', 'current'].map { |name| Trello::List.new(name: name) }
    scrummy_board.stubs(:lists).returns(lists)

    # Act
    is_scrummy = ScrumBacklog.scrummy_trello_board?(scrummy_board)

    # Assert
    assert is_scrummy
  end

  test "expects trello board NOT to be identified as scrummy" do
    # Arrange
    unscrummy_board = Trello::Board.new(id: 'non-scrummy-board')
    lists = ['Todo', 'Doing', 'Done'].map { |name| Trello::List.new(name: name) }
    unscrummy_board.stubs(:lists).returns(lists)

    # Act
    is_scrummy = ScrumBacklog.scrummy_trello_board?(unscrummy_board)

    # Assert
    assert_not is_scrummy
  end

  test "expects to find backlog by trello board id" do
    # Arrange
    existing_backlog = scrum_backlogs(:scrummy)
    trello_board = Trello::Board.new(id: existing_backlog.trello_board_id)

    # Act
    backlog = ScrumBacklog.by_trello_board_or_new(trello_board)

    # Assert
    assert_equal existing_backlog, backlog
  end

  test "expects to create backlog by trello board id" do
    # Arrange
    trello_board = Trello::Board.new(id: 'trello-id')

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
