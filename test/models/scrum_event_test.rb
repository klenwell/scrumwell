require 'test_helper'

class ScrumEventTest < ActiveSupport::TestCase
  test "creates new event" do
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
end
