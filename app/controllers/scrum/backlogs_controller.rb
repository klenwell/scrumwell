module Scrum
  class BacklogsController < ApplicationController
    before_action :set_scrum_backlog, only: [:show, :edit, :update, :destroy]

    # GET /scrum_backlogs
    # GET /scrum_backlogs.json
    def index
      @scrum_backlogs = ScrumBacklog.all
    end

    # GET /scrum_backlogs/1
    # GET /scrum_backlogs/1.json
    def show; end

    # GET /scrum_backlogs/new
    def new
      @scrum_backlog = ScrumBacklog.new
    end

    # GET /scrum_backlogs/1/edit
    def edit; end

    # POST /scrum_backlogs
    # POST /scrum_backlogs.json
    # rubocop: disable Metrics/AbcSize
    def create
      trello_board_id = scrum_backlog_params[:trello_board_id]
      trello_board = TrelloService.board(trello_board_id)

      unless trello_board
        redirect_to trello_boards_path, notice: 'Trello backlog not found.'
        return
      end

      @scrum_backlog = ScrumBacklog.new(trello_board_id: trello_board.id,
                                        trello_url: trello_board.url,
                                        name: trello_board.name,
                                        last_board_activity_at: trello_board.last_activity_date,
                                        last_pulled_at: Time.now.utc)

      respond_to do |format|
        if @scrum_backlog.save
          format.html { redirect_to @scrum_backlog, notice: 'Backlog was successfully created.' }
          format.json { render :show, status: :created, location: @scrum_backlog }
        else
          format.html { render :new }
          format.json { render json: @scrum_backlog.errors, status: :unprocessable_entity }
        end
      end
    end
    # rubocop: enable Metrics/AbcSize

    # PATCH/PUT /scrum_backlogs/1
    # PATCH/PUT /scrum_backlogs/1.json
    def update
      respond_to do |format|
        if @scrum_backlog.update(scrum_backlog_params)
          format.html { redirect_to @scrum_backlog, notice: 'Backlog was successfully updated.' }
          format.json { render :show, status: :ok, location: @scrum_backlog }
        else
          format.html { render :edit }
          format.json { render json: @scrum_backlog.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /scrum_backlogs/1
    # DELETE /scrum_backlogs/1.json
    def destroy
      @scrum_backlog.destroy
      respond_to do |format|
        format.html {
          redirect_to scrum_backlogs_url, notice: 'Backlog was successfully destroyed.'
        }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_scrum_backlog
      @scrum_backlog = ScrumBacklog.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrum_backlog_params
      params.require(:scrum_backlog).permit(:trello_board_id, :trello_url, :name,
                                            :last_board_activity_at, :last_pulled_at)
    end
  end
end
