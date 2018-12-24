module Trello
  class BoardsController < ApplicationController
    before_action :set_active_boards, only: [:index, :scrum]

    # GET trello/boards/
    def index
      @boards = @boards.sort_by(&:last_activity_date).reverse
    end

    # GET trello/boards/scrum
    def scrum
      @boards = @boards.keep_if { |b| ScrumBoard.scrummy_trello_board?(b) }
      @boards = @boards.sort_by(&:last_activity_date).reverse
      render :index
    end

    # GET trello/board/:id
    def show
      @trello = TrelloService.new
      @trello_board = TrelloService.board(params[:id])
      @scrum_board = ScrumBoard.find_by(trello_board_id: @trello_board.id)
    end

    # POST trello/board/import
    def import
      # Send import job to processor
      @trello_board = TrelloService.board(params[:id])

      # Redirect to imports page
      redirect_to trello_imports_path, notice: 'TODO: start import.'
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
