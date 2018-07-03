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

  test "expects sprint to be over" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.ended_on = Time.zone.yesterday
    sprint.save!

    # Act
    is_over = sprint.over?

    # Assert
    assert Time.zone.yesterday < Time.zone.today
    assert is_over
  end

  test "expects sprint to not be over yet" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.ended_on = Time.zone.today
    sprint.save!

    # Act
    is_over = sprint.over?

    # Assert
    assert_not is_over
  end
end
