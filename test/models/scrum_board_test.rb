#
# rake test TEST=test/models/scrum_board_test.rb
#
require 'test_helper'

class ScrumBoardTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects trello board to be identified as scrummy" do
    # Arrange
    scrummy_board = mock_trello_board

    # Act
    is_scrummy = ScrumBoard.scrummy_trello_board?(scrummy_board)

    # Assert
    assert is_scrummy
  end

  test "expects trello board NOT to be identified as scrummy" do
    # Arrange
    unscrummy_board = MockTrelloBoard.new(name: 'Unscrummy Board')

    # Act
    is_scrummy = ScrumBoard.scrummy_trello_board?(unscrummy_board)

    # Assert
    assert_not is_scrummy
  end

  test "expects to find scrum board by trello board id" do
    # Arrange
    existing_board = scrum_boards(:scrummy)
    trello_board = mock_trello_board
    trello_board.id = existing_board.trello_board_id

    # Act
    board = ScrumBoard.find_by(trello_board_id: trello_board.id)

    # Assert
    assert_equal existing_board, board
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

  test "expects to identify queues" do
    # Arrange
    wish_heap_queue = scrum_queues(:wish_heap)
    project_backlog_queue = scrum_queues(:project_backlog)
    sprint_backlog_queue = scrum_queues(:sprint_backlog)
    active_sprint_queue = scrum_queues(:active_sprint)

    # Act
    scrum_board = scrum_boards(:scrummy)

    # Assert
    assert_equal wish_heap_queue, scrum_board.wish_heap
    assert_equal project_backlog_queue, scrum_board.project_backlog
    assert_equal sprint_backlog_queue, scrum_board.sprint_backlog
    assert_equal active_sprint_queue, scrum_board.active_sprint
  end

  test "expects board created_at timestamp to match board creation event timestamp" do
    # Arrange
    ScrumEvent.any_instance.stubs(:trello_data).returns({})
    trello_board_created_at = Time.zone.yesterday.beginning_of_day
    trello_import = trello_imports(:complete)
    scrum_board = trello_import.board
    contributor = scrum_contributors(:developer)
    scrum_event = ScrumEvent.create(eventable: scrum_board,
                                    trello_import: trello_import,
                                    trello_type: 'createBoard',
                                    trello_member_id: contributor.trello_member_id,
                                    occurred_at: trello_board_created_at)

    # Assume
    assert scrum_event.creates_board?, scrum_event
    assert_not_equal trello_board_created_at, scrum_board.created_at

    # Act
    scrum_board.digest_latest_event(scrum_event)

    # Assert
    assert_equal trello_board_created_at, scrum_board.created_at
  end
end
