module Scrum
  class SprintsController < ApplicationController
    before_action :authenticate
    before_action :set_scrum_sprint, only: [:show]

    # GET /scrum/sprints
    # GET /scrum/sprints.json
    def index
      @scrum_sprints = ScrumSprint.all
    end

    # GET /scrum/boards/:board_id/sprints/new
    def new
      @scrum_sprint = ScrumSprint.new
      @scrum_sprint.scrum_board = ScrumBoard.find(params[:board_id])
    end

    # GET /scrum/sprints/1
    # GET /scrum/sprints/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_scrum_sprint
      @scrum_sprint = ScrumSprint.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrum_backlog_params
      params.require(:scrum_sprint).permit(:scrum_backlog_id, :trello_list_id, :trello_pos,
                                           :name, :started_on, :ended_on)
    end
  end
end
