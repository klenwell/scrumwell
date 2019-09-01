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

  test "expects event to add contributor to story" do
    # Arrange
    trello_import = trello_imports(:in_progress)
    story = scrum_stories(:incomplete)
    contributor = scrum_contributors(:developer)
    story.scrum_board = trello_import.board
    story.save!

    # Mock addMemberToCard action.
    action_data = {
      'card' => { 'id' => story.trello_card_id, 'name' => story.title },
      'member' => { 'id' => contributor.trello_member_id }
    }
    trello_action = MockTrelloAction.new(id: 'tests-card-creation',
                                         type: 'addMemberToCard',
                                         member_creator_id: contributor.trello_member_id,
                                         date: Time.zone.yesterday.beginning_of_day,
                                         data: action_data)

    # Assume
    assert story.contributors.empty?

    # Act
    event = ScrumEvent.create_from_trello_import(trello_import, trello_action)

    # Assert
    assert event.updates_story_contributor?
    assert_equal 1, story.contributors.count
    assert_equal contributor, story.contributors.first
  end

  test "expects to move story for event even when story does not yet exist" do
    # For more information, see https://github.com/klenwell/scrumwell/issues/36
    # Arrange
    trello_import = trello_imports(:in_progress)
    contributor = scrum_contributors(:developer)
    trello_card_id = 'test-card'

    # Stub Trello API response for card
    stub_trello_response
    card_data = { 'last_activity_date' => Time.zone.now - 2.days }
    ScrumStory.stubs(:points_from_card).returns(1)
    ScrumStory.any_instance.stubs(:trello_data).returns(card_data)

    # Mock addMemberToCard action.
    action_data = {
      "old" => { "idList" => "old-list-id" },
      "card" => { "idList" => "new-list-id", "id" => trello_card_id, "name" => "Mock Card" },
      "listBefore" => { "id" => "old-list-id", "name" => "Current Sprint" },
      "listAfter" => { "id" => "new-list-id", "name" => "Sprint 20190901 Completed" }
    }
    trello_action = MockTrelloAction.new(id: 'issue-36-fix',
                                         type: 'updateCard',
                                         member_creator_id: contributor.trello_member_id,
                                         date: Time.zone.yesterday.beginning_of_day,
                                         data: action_data)

    # Assume
    assert ScrumStory.find_by(trello_card_id: trello_card_id).nil?

    # Act
    event = ScrumEvent.create_from_trello_import(trello_import, trello_action)

    # Assert
    assert_equal 'changed_queue', event.action
    assert ScrumStory.find_by(trello_card_id: trello_card_id).present?
  end
end
