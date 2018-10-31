module Scrum
  class StoriesController < ApplicationController
    before_action :authenticate
    before_action :set_story, only: [:show]

    # GET /scrum/user_stories/1
    # GET /scrum/user_stories/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_story
      @story = ScrumStory.find(params[:id])
    end
  end
end
