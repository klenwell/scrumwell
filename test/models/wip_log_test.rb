#
# rake test TEST=test/models/wip_log_test.rb
#
require 'test_helper'

class WipLogTest < ActiveSupport::TestCase
  test "expects to create WIP log" do
    # Arrange
    scrum_event = scrum_events(:creates_card)

    # Act
    wip_log = WipLog.create_from_event(scrum_event)

    # Assert
    assert_equal scrum_event, wip_log.event
  end

  test "expects to create WIP log even when board has no completed queues" do
    # For more information, see https://github.com/klenwell/scrumwell/issues/36
    # Arrange
    board = ScrumBoard.create!(name: 'Test Board')
    trello_import = TrelloImport.create!(scrum_board_id: board.id)
    scrum_event = ScrumEvent.create!(trello_import_id: trello_import.id,
                                     occurred_at: Time.zone.now - 1.day)

    # Assume
    assert scrum_event.board.completed_queues.first.nil?

    # Act
    wip_log = WipLog.create_from_event(scrum_event)

    # Assert
    assert_equal scrum_event, wip_log.event
    assert_equal({ "d7" => 0, "d14" => 0, "d28" => 0, "d42" => 0, "all" => 0 },
                 wip_log.daily_velocity)
  end
end
