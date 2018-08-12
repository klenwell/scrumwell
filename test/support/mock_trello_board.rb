#
# MockTrelloBoard
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
