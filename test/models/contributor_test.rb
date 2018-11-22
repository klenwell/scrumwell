require 'test_helper'

class ContributorTest < ActiveSupport::TestCase
  test "expects to create new contributor" do
    # Arrange
    params = {
      username: 'rails_dev',
      full_name: 'Rails Developer'
    }

    # Assume
    contributors_before = Contributor.count

    # Act
    contributor = Contributor.create(params)

    # Assert
    assert_equal params[:username], contributor.username
    assert contributors_before + 1, Contributor.count
  end
end
