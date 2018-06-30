require 'test_helper'

class ScrumBacklogTest < ActiveSupport::TestCase
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
end
