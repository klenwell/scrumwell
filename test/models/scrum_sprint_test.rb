require 'test_helper'

class ScrumSprintTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects sprint to be valid" do
    # Arrange
    board = scrum_boards(:scrummy)

    # Act
    sprint = ScrumSprint.new(scrum_board_id: board.id)

    # Assert
    assert sprint.valid?, sprint.errors.messages
    assert_equal board, sprint.board
  end

  test "expects sprint to be current" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.update(ended_on: Time.zone.today)

    # Assume
    assert_equal Time.zone.today, sprint.ended_on

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
