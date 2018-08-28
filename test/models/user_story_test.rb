require 'test_helper'

class UserStoryTest < ActiveSupport::TestCase
  test "expects to create a new user story" do
    story = UserStory.create!(trello_card_id: 'user-story',
                              trello_short_url: 'https://trello.com/c/whatever',
                              trello_name: 'As a user, I want a story.',
                              title: 'As a user, I want a story.',
                              description: 'This is the first user story.',
                              points: 1,
                              completed_at: Time.zone.now - 1.hour,
                              last_imported_at: Time.zone.now - 1.hour)

    assert_equal 1, story.points
  end
end
