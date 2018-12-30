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
      trello_board_id = params[:id]

      # Existing boards should be updated.
      existing_board = ScrumBoard.find_by(trello_board_id: trello_board_id)
      if existing_board.present?
        return redirect_to scrum_board_path(existing_board), notice: 'Board already exists.'
      end

      # Create import.
      trello_board = TrelloService.board(trello_board_id)
      scrum_board = ScrumBoard.find_or_create_by_trello_board(trello_board)
      import = TrelloImport.create(scrum_board: scrum_board)

      # Hand off to worker.
      TrelloBoardImportWorker.perform_async(import.id)

      # Redirect to imports page
      redirect_to trello_imports_path, notice: 'Import started.'
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
