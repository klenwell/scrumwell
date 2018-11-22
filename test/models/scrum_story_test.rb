# rake test TEST=test/models/scrum_story_test.rb
require 'test_helper'

class ScrumStoryTest < ActiveSupport::TestCase
  test "expects to create new story" do
    # Arrange
    # Need to stub out some mock data
    stub_trello_response
    ScrumStory.stubs(:points_from_card).returns(1)

    # Requires member_ids for after_create associate_contributors callback
    ScrumStory.any_instance.stubs(:trello_data).returns({})

    params = {
      scrum_board: scrum_boards(:scrummy),
      trello_card_id: 'SH10151',
      title: '2 Wicky'
    }

    # Assume
    stories_before = ScrumStory.count

    # Act
    story = ScrumStory.create(params)

    # Assert
    assert story.persisted?
    assert_equal params[:title], story.title
    assert_equal stories_before + 1, ScrumStory.count
  end

  test "expects existing contributor to be associated with created story" do
    # Arrange
    developer = contributors(:developer)
    params = {
      scrum_board: scrum_boards(:scrummy),
      trello_card_id: 'SH10151',
      title: '2 Wicky'
    }

    # Need to stub out some mock data
    stub_trello_response
    ScrumStory.stubs(:points_from_card).returns(1)
    ScrumStory.any_instance.stubs(:trello_member_ids).returns([developer.trello_member_id])

    # Assume
    stories_before = ScrumStory.count
    contributions_before = Contribution.count

    # Act
    story = ScrumStory.create(params)

    # Assert
    assert_equal stories_before + 1, ScrumStory.count
    assert_equal contributions_before + 1, Contribution.count
    assert_equal 1, story.contributors.count
    assert_equal developer.id, story.contributors.first.id
  end
end
