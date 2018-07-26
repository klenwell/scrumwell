require 'test_helper'

class Scrum::SprintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @scrum_sprint = scrum_sprints(:most_recent)
  end

  test "expect scrum master can edit board" do
    # Arrange
    login_as(email: 'testing@gmail.com', scrum_master: true)

    # Act
    get edit_scrum_sprint_url(@scrum_sprint)

    # Assert
    assert_response :success
    assert_select 'form small.form-text', 'Started'
  end
end
