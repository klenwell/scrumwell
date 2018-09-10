ENV['RAILS_ENV'] ||= 'test'
Dir[Rails.root.join('test', 'support', '**', '*')].each { |f| require f }
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'webmock/minitest'

# Allow access to localhost while mocking external resources
WebMock.disable_net_connect!(allow_localhost: true)

module TrelloMock
  def stub_trello_response(api_response={}, status=200)
    base_uri = Regexp.new 'https://api.trello.com/'
    stub_request(:any, base_uri).to_return(body: api_response.to_json, status: status)
  end
end

module OmniAuthMock
  # Call to auth endpoint will automatically redirect to auth callback.
  # https://github.com/omniauth/omniauth/wiki/Integration-Testing#omniauthconfigtest_mode
  OmniAuth.config.test_mode = true

  def stub_omniauth(options={})
    # Needs to be different email than user fixtures
    email = options[:email] || 'testing@gmail.com'
    google_id = rand(100_000_0..999_999_9).to_s

    # https://github.com/omniauth/omniauth/wiki/Integration-Testing#omniauthconfigmock_auth
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: google_id,
      credentials: {
        token: 'mock-token'
      },
      info: {
        email: email
      }
    )
  end
end

class ActiveSupport::TestCase
  include TrelloMock
  include OmniAuthMock

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Mock authentication.
  def login_as(options={})
    email = options[:email] || 'testing@gmail.com'
    as_scrum_master = options.fetch(:scrum_master, false)

    stub_omniauth(email: email)
    get '/auth/google_oauth2'

    mock_scrum_master if as_scrum_master

    # Must call this to hit the auth callback where session is set.
    # http://guides.rubyonrails.org/testing.html#creating-articles-integration
    follow_redirect!
  end

  def mock_scrum_master
    ApplicationController.any_instance.stubs(:auth_scrum_masters).returns(true)
  end

  def mock_sign_out
    ApplicationController.any_instance.stubs(:signed_in?).returns(false)
  end

  def mock_trello_board
    MockTrelloBoard.scrummy
  end
end
