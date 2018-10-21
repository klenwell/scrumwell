require 'test_helper'

class Scrum::SprintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @scrum_sprint = scrum_sprints(:most_recent)
  end

  test "expects scrum master can edit board" do
    # Arrange
    login_as(email: 'testing@gmail.com', scrum_master: true)

    # Act
    get edit_scrum_sprint_url(@scrum_sprint)

    # Assert
    assert_response :success
    assert_select 'form small.form-text', 'Started'
  end

  test "expects scrum master to update sprint stories count" do
    # Arrange
    login_as(email: 'testing@gmail.com', scrum_master: true)
    stories_count = 3

    # Assume
    assert_not_equal stories_count, @scrum_sprint.stories_count

    # Act
    params = {
      id: @scrum_sprint.id,
      stories_count: stories_count,
      story_points_completed: @scrum_sprint.story_points
    }
    patch scrum_sprint_url(@scrum_sprint), params: { scrum_sprint: params }

    # Assert
    assert_response :redirect, response.body
    assert_equal stories_count, @scrum_sprint.reload.stories_count
  end
end
