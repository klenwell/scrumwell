#
# rake test TEST=test/controllers/scrum/backlogs_controller_test.rb
#
require 'test_helper'

class ScrumBoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_trello_response

    @scrum_board = scrum_boards(:scrummy)
    @scrummy_board = mock_trello_board(id: 'scrummy-board',
                                       name: 'Scrummy Board',
                                       list_names: ['wish heap', 'backlog', 'current'])
  end

  test "expects to create backlog from Trello Board" do
    # Arrange
    TrelloService.stubs(:board).returns(@scrummy_board)

    # Act
    assert_difference('ScrumBoard.count') do
      params = { trello_board_id: @scrummy_board.id }
      post scrum_boards_url, params: { scrum_board: params }
    end

    # Assert
    created_backlog = ScrumBoard.last
    assert_redirected_to scrum_board_url(created_backlog)
    assert_equal @scrummy_board.id, created_backlog.trello_board_id
    assert_equal @scrummy_board.name, created_backlog.name
  end

  test "expects backlog not to be created when Trello Board not found" do
    # Arrange
    TrelloService.stubs(:board).returns(nil)
    backlog_count_before = ScrumBoard.count

    # Act
    params = { trello_board_id: 'not-found' }
    post scrum_boards_url, params: { scrum_board: params }

    # Assert
    assert_equal backlog_count_before, ScrumBoard.count
    assert_redirected_to trello_boards_url
  end

  test "should get index" do
    get scrum_boards_url
    assert_response :success
  end

  test "should get new" do
    get new_scrum_board_url
    assert_response :success
  end

  test "should show scrum_board" do
    get scrum_board_url(@scrum_board)
    assert_response :success
  end

  test "should get edit" do
    get edit_scrum_board_url(@scrum_board)
    assert_response :success
  end

  test "expects to update name of backlog" do
    # Arrange
    params = {
      name: 'Updated Name',
      trello_url: @scrum_board.trello_url
    }

    # Assume
    assert_not_equal params[:name], @scrum_board.name

    # Act
    patch scrum_board_url(@scrum_board), params: { scrum_board: params }
    @scrum_board.reload

    # Assert
    assert_redirected_to scrum_board_url(@scrum_board)
    assert_equal params[:name], @scrum_board.name
  end

  test "expects update to fail with invalid Trello URL" do
    # Arrange
    params = {
      name: 'Updated Name',
      trello_url: 'https://asana.com/my-scrummy-board'
    }

    # Assume
    assert_not_equal params[:name], @scrum_board.name

    # Act
    patch scrum_board_url(@scrum_board), params: { scrum_board: params }
    @scrum_board.reload

    # Assert
    # Will be redirected if update succeeded
    assert_response :success
    assert_not_equal params[:name], @scrum_board.name
  end

  test "should destroy scrum_board" do
    assert_difference('ScrumBoard.count', -1) do
      delete scrum_board_url(@scrum_board)
    end

    assert_redirected_to scrum_boards_url
  end
end
