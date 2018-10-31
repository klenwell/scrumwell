#
# rake test TEST=test/models/scrum_queue_test.rb
#
require 'test_helper'

class ScrumQueueTest < ActiveSupport::TestCase
  test "expects queue to be wish heap" do
    # Arrange
    mock_trello_list = MockTrelloList.new(name: 'Wish Heap')
    TrelloService.stubs(:list).returns(mock_trello_list)
    queue = scrum_queues(:wish_heap)

    # Act
    is_wish_heap = queue.wish_heap?

    # Assert
    assert is_wish_heap
  end

  test "expects queue to be active sprint" do
    # Arrange
    queue = scrum_queues(:active_sprint)

    # Act
    is_active_sprint = queue.active_sprint?

    # Assert
    assert is_active_sprint
  end
end
