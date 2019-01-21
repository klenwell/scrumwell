module Scrum
  class EventsController < ApplicationController
    before_action :authenticate
    before_action :set_event, only: [:show]

    # GET /scrum/events/1
    # GET /scrum/events/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = ScrumEvent.find(params[:id])
    end
  end
end
