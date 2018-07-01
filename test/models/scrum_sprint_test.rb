require 'test_helper'

class ScrumSprintTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects sprint to be valid" do
    # Arrange
    backlog = scrum_backlogs(:scrummy)

    # Act
    sprint = ScrumSprint.new(scrum_backlog_id: backlog.id)

    # Assert
    assert sprint.valid?, sprint.errors.messages
    assert_equal backlog, sprint.backlog
  end
end
