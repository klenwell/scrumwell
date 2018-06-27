require 'test_helper'

class ScrumBacklogTest < ActiveSupport::TestCase
  test "expects new scrum backlog to have TrelloService api object" do
    backlog = ScrumBacklog.new
    assert_instance_of TrelloService, backlog.api
  end

  test "expects to find backlog by trello board id" do
    # Arrange
    existing_backlog = scrum_backlogs(:scrum_backlog)
    trello_board = Trello::Board.new(id: existing_backlog.trello_board_id)

    # Act
    backlog = ScrumBacklog.by_trello_board_or_create(trello_board)

    # Assert
    assert_equal existing_backlog, backlog
  end

  test "expects to create backlog by trello board id" do
    # Arrange
    trello_board = Trello::Board.new(id: 'trello-id')

    # Assume
    backlog_count_before = ScrumBacklog.count

    # Act
    backlog = ScrumBacklog.by_trello_board_or_create(trello_board)

    # Assert
    assert_equal trello_board.id, backlog.trello_board_id
    assert_equal backlog_count_before + 1, ScrumBacklog.count
  end
end
