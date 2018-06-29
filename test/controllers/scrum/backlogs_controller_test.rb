require 'test_helper'

class ScrumBacklogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @scrum_backlog = scrum_backlogs(:scrummy)
  end

  test "should get index" do
    get scrum_backlogs_url
    assert_response :success
  end

  test "should get new" do
    get new_scrum_backlog_url
    assert_response :success
  end

  test "should create scrum_backlog" do
    assert_difference('ScrumBacklog.count') do
      params = { last_board_activity_at: @scrum_backlog.last_board_activity_at,
                 last_pulled_at: @scrum_backlog.last_pulled_at,
                 name: @scrum_backlog.name,
                 trello_board_id: @scrum_backlog.trello_board_id,
                 trello_url: @scrum_backlog.trello_url }
      post scrum_backlogs_url, params: { scrum_backlog: params }
    end

    assert_redirected_to scrum_backlog_url(ScrumBacklog.last)
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
