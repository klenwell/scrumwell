module Scrum
  class BoardsController < ApplicationController
    before_action :set_scrum_board, only: [:show, :edit, :update, :destroy]

    # GET /scrum_boards
    # GET /scrum_boards.json
    def index
      @scrum_boards = ScrumBoard.all
    end

    # GET /scrum_boards/1
    # GET /scrum_boards/1.json
    def show; end

    # GET /scrum_boards/new
    def new
      @scrum_board = ScrumBoard.new
    end

    # GET /scrum_boards/1/edit
    def edit; end

    # POST /scrum_boards
    # POST /scrum_boards.json
    # rubocop: disable Metrics/AbcSize
    def create
      trello_board_id = scrum_board_params[:trello_board_id]
      trello_board = TrelloService.board(trello_board_id)

      unless trello_board
        redirect_to trello_boards_path, notice: 'Trello backlog not found.'
        return
      end

      @scrum_board = ScrumBoard.by_trello_board_or_new(trello_board)

      respond_to do |format|
        if @scrum_board.save
          format.html { redirect_to @scrum_board, notice: 'Backlog was successfully created.' }
          format.json { render :show, status: :created, location: @scrum_board }
        else
          format.html { render :new }
          format.json { render json: @scrum_board.errors, status: :unprocessable_entity }
        end
      end
    end
    # rubocop: enable Metrics/AbcSize

    # PATCH/PUT /scrum_boards/1
    # PATCH/PUT /scrum_boards/1.json
    def update
      respond_to do |format|
        if @scrum_board.update(scrum_board_params)
          format.html { redirect_to @scrum_board, notice: 'Backlog was successfully updated.' }
          format.json { render :show, status: :ok, location: @scrum_board }
        else
          format.html { render :edit }
          format.json { render json: @scrum_board.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /scrum_boards/1
    # DELETE /scrum_boards/1.json
    def destroy
      @scrum_board.destroy
      respond_to do |format|
        format.html {
          redirect_to scrum_boards_url, notice: 'Backlog was successfully destroyed.'
        }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_scrum_board
      @scrum_board = ScrumBoard.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrum_board_params
      params.require(:scrum_board).permit(:trello_board_id, :trello_url, :name,
                                          :last_board_activity_at, :last_pulled_at)
    end
  end
end
