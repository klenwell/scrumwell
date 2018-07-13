#
# rake test TEST=test/controllers/scrum/boards_controller_test.rb
#
require 'test_helper'

class ScrumBoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
    stub_trello_response

    @scrum_board = scrum_boards(:scrummy)
    @trello_board = mock_trello_board(id: 'scrummy-board',
                                      name: 'Scrummy Board',
                                      list_names: ['wish heap', 'backlog', 'current'])
  end

  test "expects unauthenticated user to be unable to visit the index" do
    # Arrange
    sign_out

    # Act
    get scrum_boards_url

    # Assert
    assert_response :redirect
    assert_redirected_to 'http://www.example.com/authenticate'
  end

  test "expects to create scrum board from Trello Board" do
    # Arrange
    TrelloService.stubs(:board).returns(@trello_board)

    # Act
    assert_difference('ScrumBoard.count') do
      params = { trello_board_id: @trello_board.id }
      post scrum_boards_url, params: { scrum_board: params }
    end

    # Assert
    created_board = ScrumBoard.last
    assert_redirected_to scrum_board_url(created_board)
    assert_equal @trello_board.id, created_board.trello_board_id
    assert_equal @trello_board.name, created_board.name
  end

  test "expects board not to be created when Trello Board not found" do
    # Arrange
    TrelloService.stubs(:board).returns(nil)
    board_count_before = ScrumBoard.count

    # Act
    params = { trello_board_id: 'not-found' }
    post scrum_boards_url, params: { scrum_board: params }

    # Assert
    assert_equal board_count_before, ScrumBoard.count
    assert_redirected_to trello_boards_url
  end

  test "should get index" do
    # Arrange
    # TODO: Properly set up fixtures so all these stubs aren't required.
    mock_sprint_backlog = stub(story_points: 0)
    mock_board_backlog_stories = stub(count: 0)
    mock_board_backlog = stub(stories: mock_board_backlog_stories)
    ScrumBoard.any_instance.stubs(:sprint_backlog).returns(mock_sprint_backlog)
    ScrumBoard.any_instance.stubs(:backlog_points).returns(0)
    ScrumBoard.any_instance.stubs(:estimate_wish_heap_points).returns(0)
    ScrumBoard.any_instance.stubs(:backlog).returns(mock_board_backlog)

    # Act
    get scrum_boards_url

    # Assert
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

  test "expects to update name of board" do
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
