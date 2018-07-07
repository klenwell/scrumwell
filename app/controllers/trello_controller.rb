class TrelloController < ApplicationController
  def boards_index
    @trello = TrelloService.new

    # If you don't filter out the boards with nil for last_activity_date, sort_by will
    # choke. Why do some boards have a nil value for this field? ¯\_(ツ)_/¯
    active_boards = @trello.public_boards.keep_if { |b| b.last_activity_date.present? }
    @boards = active_boards.sort_by(&:last_activity_date).reverse
  end

  def orgs_index
    @trello = TrelloService.new
    @orgs = @trello.public_orgs
  end

  def orgs_boards_index
    @org = TrelloService.org(params[:id])
    active_boards = @org.boards.keep_if { |b| b.last_activity_date.present? }
    @boards = active_boards.sort_by(&:last_activity_date).reverse
  end

  # GET trello/boards/:id
  def boards_show
    @trello = TrelloService.new
    @board = TrelloService.board(params[:id])
    @backlog = ScrumBacklog.find_by(trello_board_id: @board.id)
  end
end
