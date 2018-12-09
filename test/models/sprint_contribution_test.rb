require 'test_helper'

class SprintContributionTest < ActiveSupport::TestCase
  test "expects to create new sprint contribution" do
    # Arrange
    developer = scrum_contributors(:developer)
    sprint = scrum_queues(:completed_sprint)

    # Act
    sprint_contribution = SprintContribution.create!(
      scrum_contributor: developer,
      scrum_queue: sprint,
      story_points: 10,
      event_count: 24
    )

    # Assert
    assert_equal developer.id, sprint_contribution.contributor.id
    assert_equal 10, sprint_contribution.story_points
  end
end
