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

    # POST /scrum/boards/:board_id/sprints
    # rubocop: disable Metrics/AbcSize
    def create
      @scrum_sprint = ScrumSprint.create(scrum_sprint_params)

      respond_to do |format|
        if @scrum_sprint.save
          format.html {
            redirect_to ScrumBoard.find(params[:board_id]),
                        notice: 'Sprint was successfully created.'
          }
          format.json { render :show, status: :created, location: @scrum_sprint }
        else
          format.html { render :new }
          format.json { render json: @scrum_sprint.errors, status: :unprocessable_entity }
        end
      end
    end
    # rubocop: enable Metrics/AbcSize

    # GET /scrum/sprints/1
    # GET /scrum/sprints/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_scrum_sprint
      @scrum_sprint = ScrumSprint.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrum_sprint_params
      params.require(:scrum_sprint).permit(
        :scrum_board_id, :name, :started_on, :ended_on, :story_points_committed,
        :story_points_completed, :average_story_size, :backlog_story_points,
        :backlog_stories_count, :wish_heap_stories_count, :notes
      )
    end
  end
end
