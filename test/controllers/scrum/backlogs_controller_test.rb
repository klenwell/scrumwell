#
# rake test TEST=test/controllers/scrum/backlogs_controller_test.rb
#
require 'test_helper'

class ScrumBacklogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @scrum_backlog = scrum_backlogs(:scrummy)
    @scrummy_board = Trello::Board.new(id: 'scrummy-board', name: 'Scrummy Board')
    lists = ['wish heap', 'backlog', 'current'].map { |name| Trello::List.new(name: name) }
    @scrummy_board.stubs(:lists).returns(lists)
  end

  test "expects to create backlock from Trello Board" do
    # Arrange
    TrelloService.stubs(:board).returns(@scrummy_board)

    # Act
    assert_difference('ScrumBacklog.count') do
      params = { trello_board_id: @scrummy_board.id }
      post scrum_backlogs_url, params: { scrum_backlog: params }
    end

    # Assert
    created_backlog = ScrumBacklog.last
    assert_redirected_to scrum_backlog_url(created_backlog)
    assert_equal @scrummy_board.id, created_backlog.trello_board_id
    assert_equal @scrummy_board.name, created_backlog.name
  end

  test "expects backlog not to be created when Trello Board not found" do
    # Arrange
    TrelloService.stubs(:board).returns(nil)
    backlog_count_before = ScrumBacklog.count

    # Act
    params = { trello_board_id: 'not-found' }
    post scrum_backlogs_url, params: { scrum_backlog: params }

    # Assert
    assert_equal backlog_count_before, ScrumBacklog.count
    assert_redirected_to trello_boards_url
  end

  test "should get index" do
    get scrum_backlogs_url
    assert_response :success
  end

  test "should get new" do
    get new_scrum_backlog_url
    assert_response :success
  end

  test "should show scrum_backlog" do
    get scrum_backlog_url(@scrum_backlog)
    assert_response :success
  end

  test "should get edit" do
    get edit_scrum_backlog_url(@scrum_backlog)
    assert_response :success
  end

  test "should update scrum_backlog" do
    params = { last_board_activity_at: @scrum_backlog.last_board_activity_at,
               last_pulled_at: @scrum_backlog.last_pulled_at,
               name: @scrum_backlog.name,
               trello_board_id: @scrum_backlog.trello_board_id,
               trello_url: @scrum_backlog.trello_url }
    patch scrum_backlog_url(@scrum_backlog), params: { scrum_backlog: params }
    assert_redirected_to scrum_backlog_url(@scrum_backlog)
  end

  test "should destroy scrum_backlog" do
    assert_difference('ScrumBacklog.count', -1) do
      delete scrum_backlog_url(@scrum_backlog)
    end

    assert_redirected_to scrum_backlogs_url
  end
end
