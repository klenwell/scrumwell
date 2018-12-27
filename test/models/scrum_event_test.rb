#
# rake test TEST=test/models/scrum_event_test.rb
#
require 'test_helper'

class ScrumEventTest < ActiveSupport::TestCase
  test "expects to create new event" do
    # Arrange
    trello_import = trello_imports(:in_progress)
    eventable = scrum_stories(:complete)
    params = {
      trello_import_id: trello_import.id,
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

    contributor = scrum_contributors(:developer)
    trello_import = trello_imports(:complete)
    action_data = {
      'list' => { 'id' => trello_import.board.wish_heap.trello_list_id },
      'card' => { 'id' => 'test-card', 'name' => 'Mock Test Card' }
    }
    trello_action = MockTrelloAction.new(id: 'tests-card-creation',
                                         type: 'createCard',
                                         member_creator_id: contributor.trello_member_id,
                                         date: Time.zone.yesterday.beginning_of_day,
                                         data: action_data)
    event = ScrumEvent.create_from_trello_import(trello_import, trello_action)

    # Assume
    assert_equal trello_action.date, event.occurred_at
    assert_equal 'created', event.action
    assert_equal 'card', event.trello_object
    assert_equal trello_import.board.wish_heap.trello_list_id, event.trello_list_id

    # Act
    story = event.create_story_for_board(trello_import.board)

    # Assert
    assert_equal event.occurred_at, story.created_at
    assert_equal trello_action.date, story.created_at
  end
end
