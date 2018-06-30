ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'webmock/minitest'

module TrelloMock
  def stub_trello_response(api_response={}, status=200)
    base_uri = Regexp.new 'https://api.trello.com/'
    stub_request(:any, base_uri).to_return(body: api_response.to_json, status: status)
  end
end

class ActiveSupport::TestCase
  include TrelloMock

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
