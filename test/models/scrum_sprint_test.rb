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

  test "expects sprint to be current" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.ended_on = Time.zone.today
    sprint.save!

    # Assert
    assert sprint.current?
    assert_not sprint.over?
    assert_not sprint.future?
  end

  test "expects sprint to be over" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.ended_on = Time.zone.yesterday
    sprint.save!

    # Assert
    assert sprint.over?
  end

  test "expect sprint to have two stories ordered by trello_pos" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    first_story = user_stories(:complete)

    # Assert
    assert_equal 2, sprint.stories.count
    assert_equal first_story, sprint.stories.first
  end
end
