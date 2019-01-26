module Scrum
  class QueuesController < ApplicationController
    before_action :authenticate
    before_action :auth_scrum_masters, only: [:new, :create, :edit, :update]
    before_action :set_queue, only: [:edit, :update, :show]
    before_action :set_scrum_queue_tab, only: [:show]

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

    # GET /scrum/sprints/:id/edit
    def edit; end

    # PATCH/PUT /scrum/sprints/:id
    # PATCH/PUT /scrum_boards/:id.json
    def update
      respond_to do |format|
        if @scrum_sprint.update(scrum_sprint_params)
          format.html {
            redirect_to @scrum_sprint.board, notice: 'Sprint was successfully updated.'
          }
          format.json { render :show, status: :ok, location: @scrum_sprint }
        else
          format.html { render :edit }
          format.json { render json: @scrum_sprint.errors, status: :unprocessable_entity }
        end
      end
    end

    # GET /scrum/queues/1
    # GET /scrum/queues/1/stories
    # GET /scrum/queues/1/contributors
    # GET /scrum/queues/1/events
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_queue
      @queue = ScrumQueue.find(params[:id])
    end

    def set_scrum_queue_tab
      valid_tabs = ['stories', 'contributors', 'events']
      @tab = request.fullpath.split('/').last
      @tab = valid_tabs.first unless valid_tabs.include? @tab
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scrum_sprint_params
      params.require(:scrum_sprint).permit(
        :scrum_board_id, :name, :started_on, :ended_on, :notes
      )
    end
  end
end
