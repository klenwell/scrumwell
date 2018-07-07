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
  # rubocop: disable Metrics/AbcSize
  def mock_trello_board(params={})
    # Optional params
    trello_id = params[:id] || 'trello-id'
    trello_url = params[:url] || 'https://trello.com/b/id/trello-name'
    trello_name = params[:name] || 'Trello Board Name'
    list_names = params[:list_names] || []

    trello_board = Trello::Board.new(id: trello_id, name: trello_name)

    # url is read-only
    # https://github.com/jeremytregunna/ruby-trello/blob/master/lib/trello/board.rb#L21
    trello_board.stubs(:url).returns(trello_url)

    # Mock lists: need to stub out cards attr or will get a map error.
    lists = list_names.map do |name|
      list = Trello::List.new(name: name)
      list.stubs(:cards).returns([])
      list
    end
    trello_board.stubs(:lists).returns(lists)

    trello_board
  end
  # rubocop: enable Metrics/AbcSize
end
