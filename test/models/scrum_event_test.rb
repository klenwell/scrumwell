require 'test_helper'

class ScrumEventTest < ActiveSupport::TestCase
  test "expects to create new event" do
    # Arrange
    eventable = scrum_stories(:complete)
    params = {
      eventable_id: eventable.id,
      eventable_type: eventable
    }

    # Assume
    events_before = ScrumEvent.count

    # Act
    event = ScrumEvent.create(params)

    # Assert
    assert_equal event.eventable_id, eventable.id
    assert events_before + 1, ScrumEvent.count
  end

  test "expects to match story created_at to event occurred_at for story created event" do
    # Arrange
    # Need to stub out some mock data
    stub_trello_response
    ScrumStory.stubs(:points_from_card).returns(1)

    board = scrum_boards(:scrummy)
    contributor = scrum_contributors(:developer)
    action_data = {
      'list' => { 'id' => board.wish_heap.trello_list_id },
      'card' => { 'id' => 'test-card', 'name' => 'Mock Test Card' }
    }
    trello_action = MockTrelloAction.new(id: 'tests-card-creation',
                                         type: 'createCard',
                                         member_creator_id: contributor.trello_member_id,
                                         date: Time.zone.yesterday.beginning_of_day,
                                         data: action_data)
    event = ScrumEvent.create_from_trello_board_event(board, trello_action)

    # Assume
    assert_equal trello_action.date, event.occurred_at
    assert_equal 'created', event.action
    assert_equal 'card', event.trello_object
    assert_equal board.wish_heap.trello_list_id, event.trello_list_id

    # Act
    story = event.create_story_for_board(board)

    # Assert
    assert_equal event.occurred_at, story.created_at
    assert_equal trello_action.date, story.created_at
  end
end
