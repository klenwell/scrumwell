module Trello
  class BoardsController < ApplicationController
    before_action :set_active_boards, only: [:index, :scrum]

    def index
      @boards = @boards.sort_by(&:last_activity_date).reverse
    end

    def scrum
      @boards = @boards.keep_if { |b| ScrumBoard.scrummy_trello_board?(b) }
      @boards = @boards.sort_by(&:last_activity_date).reverse
      render :index
    end

    # GET trello/boards/:id
    def show
      @trello = TrelloService.new
      @trello_board = TrelloService.board(params[:id])
      @scrum_board = ScrumBoard.find_by(trello_board_id: @trello_board.id)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_active_boards
      @trello = TrelloService.new

      # If you don't filter out the boards with nil for last_activity_date, sort_by will
      # choke. Why do some boards have a nil value for this field? ¯\_(ツ)_/¯
      @boards = @trello.public_boards.keep_if { |b| b.last_activity_date.present? }
    end
  end
end
