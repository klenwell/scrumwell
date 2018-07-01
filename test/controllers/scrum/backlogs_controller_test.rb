#
# rake test TEST=test/controllers/scrum/backlogs_controller_test.rb
#
require 'test_helper'

class ScrumBacklogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_trello_response

    @scrum_backlog = scrum_backlogs(:scrummy)
    @scrummy_board = mock_trello_board(id: 'scrummy-board',
                                       name: 'Scrummy Board',
                                       list_names: ['wish heap', 'backlog', 'current'])
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

  test "expects to update name of backlog" do
    # Arrange
    params = {
      name: 'Updated Name',
      trello_url: @scrum_backlog.trello_url
    }

    # Assume
    assert_not_equal params[:name], @scrum_backlog.name

    # Act
    patch scrum_backlog_url(@scrum_backlog), params: { scrum_backlog: params }
    @scrum_backlog.reload

    # Assert
    assert_redirected_to scrum_backlog_url(@scrum_backlog)
    assert_equal params[:name], @scrum_backlog.name
  end

  test "expects update to fail with invalid Trello URL" do
    # Arrange
    params = {
      name: 'Updated Name',
      trello_url: 'https://asana.com/my-scrummy-board'
    }

    # Assume
    assert_not_equal params[:name], @scrum_backlog.name

    # Act
    patch scrum_backlog_url(@scrum_backlog), params: { scrum_backlog: params }
    @scrum_backlog.reload

    # Assert
    # Will be redirected if update succeeded
    assert_response :success
    assert_not_equal params[:name], @scrum_backlog.name
  end

  test "should destroy scrum_backlog" do
    assert_difference('ScrumBacklog.count', -1) do
      delete scrum_backlog_url(@scrum_backlog)
    end

    assert_redirected_to scrum_backlogs_url
  end
end
