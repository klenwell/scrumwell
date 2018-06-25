module Trello
  class BoardsController < ApplicationController
    before_action :set_trello_board, only: [:show, :edit, :update, :destroy]

    # GET /trello/boards
    def index
      @boards = TrelloBoard.active
      @trello = TrelloService.new
    end

    # GET trello/boards/:id
    def show; end

    def edit; end

    def update; end

    def destroy; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_trello_board
      @trello_board = TrelloBoard.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trello_board_params
      params.require(:trello_board).permit(:name)
    end
  end
end
