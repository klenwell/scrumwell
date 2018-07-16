require 'test_helper'

class ScrumSprintTest < ActiveSupport::TestCase
  setup do
    stub_trello_response
  end

  test "expects sprint to be valid" do
    # Arrange
    board = scrum_boards(:scrummy)

    # Act
    sprint = ScrumSprint.new(scrum_board_id: board.id,
                             name: 'Test 20180701',
                             started_on: '2018-07-01',
                             ended_on: '2018-07-15',
                             story_points_completed: 10)

    # Assert
    assert sprint.valid?, sprint.errors.messages
    assert_equal board, sprint.board
  end

  test "expects sprint to be current" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    ended_on = Time.zone.today
    started_on = ended_on - 2.weeks

    # Need to stub sprint.board to return a valid trello board or will get error on update.
    sprint.board.stubs(:trello_board).returns(mock_trello_board)

    sprint.update(started_on: started_on, ended_on: ended_on)

    # Assume
    assert_equal ended_on, sprint.ended_on

    # Assert
    assert sprint.current?
    assert_not sprint.over?
    assert_not sprint.future?
  end

  test "expects sprint to be over" do
    # Arrange
    sprint = scrum_sprints(:most_recent)
    sprint.update(ended_on: Time.zone.yesterday)

    # Assert
    assert sprint.over?
  end

  test "expects sprint to have ended after other sprint" do
    # Arrange
    sprint = ScrumSprint.new(ended_on: Time.zone.today)
    other_sprint = ScrumSprint.new(ended_on: Time.zone.today - 2.weeks)

    # Assert
    assert sprint.ended_after?(other_sprint)
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
