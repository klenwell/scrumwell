ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'webmock/minitest'

# Allow access to localhost while mocking external resources
WebMock.disable_net_connect!(allow_localhost: true)

#
# Mock Trello Classes
# TODO: Move into own directory
# See https://stackoverflow.com/a/33610647/1093087
#
class MockTrelloBoard
  attr_accessor :id, :name, :url, :last_activity_date, :lists

  # rubocop: disable Metrics/AbcSize
  def self.scrummy
    # Board
    board = MockTrelloBoard.new(name: 'Scrummy Board')
    current_sprint_list, completed_sprint_list = board.init_current_sprint

    # Sprint Lists
    board.lists << board.init_wish_heap
    board.lists << board.init_backlog
    board.lists << current_sprint_list
    board.lists << completed_sprint_list
    board.lists << board.init_first_sprint
    board.lists << board.init_second_sprint
    board.lists << board.init_third_sprint

    board
  end
  # rubocop: enable Metrics/AbcSize

  def initialize(params={})
    @name = params[:name]
    @id = params[:id] || @name.parameterize
    @url = format('https://trello.com/b/%s/%s', @id, @name.parameterize)
    @last_activity_date = Time.zone.now
    @lists = []
    @current_sprint_end_date = Time.zone.today + 7.days
  end

  def init_wish_heap
    wish_heap = MockTrelloList.new(name: 'Wish Heap')
    wish_heap.add_card(name: 'Wish Heap Story 1')
    wish_heap.add_card(name: 'Wish Heap Story 2')
    wish_heap
  end

  def init_backlog
    backlog = MockTrelloList.new(name: 'Backlog')
    backlog.add_card(name: 'Backlog Story 1', points: 1)
    backlog.add_card(name: 'Backlog Story 2', points: 2)
    backlog
  end

  def init_current_sprint
    # Creates Current Sprint and Completed List
    sprint_name = ScrumSprint.name_from_date(@current_sprint_end_date)

    # Lists
    current_sprint_list = MockTrelloList.new(name: 'Current Sprint')
    completed_sprint_list = MockTrelloList.new(name: sprint_name)

    # Stories
    current_sprint_list.add_card(name: 'Current Story 1', points: 2)
    current_sprint_list.add_card(name: 'Current Story 2', points: 3)
    completed_sprint_list.add_card(name: 'Completed Story 1', points: 1)

    [current_sprint_list, completed_sprint_list]
  end

  def init_first_sprint
    days_ago = ScrumBoard::DEFAULT_SPRINT_DURATION * 3
    end_date = @current_sprint_end_date - days_ago
    sprint_name = ScrumSprint.name_from_date(end_date)
    sprint_list = MockTrelloList.new(name: sprint_name)
    sprint_list.add_card(name: 'First Sprint Story 1', points: 3)
    sprint_list.add_card(name: 'First Sprint Story 2', points: 2)
    sprint_list
  end

  def init_second_sprint
    days_ago = ScrumBoard::DEFAULT_SPRINT_DURATION * 2
    end_date = @current_sprint_end_date - days_ago
    sprint_name = ScrumSprint.name_from_date(end_date)
    sprint_list = MockTrelloList.new(name: sprint_name)
    sprint_list.add_card(name: 'Second Sprint Story 2', points: 5)
    sprint_list
  end

  def init_third_sprint
    end_date = @current_sprint_end_date - ScrumBoard::DEFAULT_SPRINT_DURATION
    sprint_name = ScrumSprint.name_from_date(end_date)
    sprint_list = MockTrelloList.new(name: sprint_name)
    sprint_list.add_card(name: 'Second Sprint Story 1', points: 2)
    sprint_list.add_card(name: 'Second Sprint Story 2', points: 5)
    sprint_list
  end
end

class MockTrelloList
  attr_accessor :id, :name, :pos, :cards

  def initialize(params={})
    @name = params[:name]
    @id = params[:id] || @name.parameterize
    @pos = params[:pos] || rand(100_000..1_000_000)
    @cards = []
  end

  def add_card(card_params={})
    @cards << MockTrelloCard.new(card_params)
  end
end

class MockTrelloCard
  attr_accessor :id, :name, :pos, :desc, :short_url, :last_activity_date, :card_labels,
                :plugin_data

  # rubocop: disable Metrics/AbcSize
  def initialize(params={})
    @name = params[:name]
    @id = params[:id] || @name.parameterize
    @pos = params[:pos] || rand(100_000..1_000_000)
    @desc = params[:desc]
    @last_activity_date = Time.zone.now
    @card_labels = []
    @plugin_data = []

    # Simulate Agile Tools plugin.
    agile_tools_plugin = OpenStruct.new(idPlugin: agile_tools_plugin_id, value: {})
    @plugin_data << agile_tools_plugin

    # Points?
    self.story_points = params[:points] if params[:points]
  end
  # rubocop: enable Metrics/AbcSize

  def agile_tools_plugin_id
    UserStory::AGILE_TOOLS_PLUGIN_ID
  end

  def story_points=(points)
    agile_tools_plugin = @plugin_data.find { |pd| pd.idPlugin == agile_tools_plugin_id }
    agile_tools_plugin.value['points'] = points.to_s
  end
end

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
