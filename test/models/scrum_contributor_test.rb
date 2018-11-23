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
end
