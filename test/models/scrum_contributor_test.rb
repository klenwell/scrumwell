#
# rake test TEST=test/models/scrum_contributor_test.rb
#
require 'test_helper'

class ScrumContributorTest < ActiveSupport::TestCase
  test "expects to create new contributor" do
    # Arrange
    params = {
      username: 'rails_dev',
      full_name: 'Rails Developer'
    }

    # Assume
    contributors_before = ScrumContributor.count

    # Act
    contributor = ScrumContributor.create(params)

    # Assert
    assert_equal params[:username], contributor.username
    assert contributors_before + 1, ScrumContributor.count
  end

  test "expects contributor to have many events" do
    # Arrange
    contributor = scrum_contributors(:developer)
    trello_import = trello_imports(:complete)
    event_count_before = ScrumEvent.count
    event_params = {
      trello_member_id: contributor.trello_member_id,
      trello_import_id: trello_import.id,
      scrum_board_id: scrum_boards(:scrummy).id,
      action: 'test',
      trello_data: {}
    }

    # Assert
    assert_equal 0, contributor.events.count

    # Act
    ScrumEvent.create!(event_params)
    ScrumEvent.create!(event_params)

    # Assert
    assert_equal event_count_before + 2, ScrumEvent.count
    assert_equal 2, contributor.events.count
  end
end
