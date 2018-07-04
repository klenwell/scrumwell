module Scrum
  class UserStoriesController < ApplicationController
    before_action :set_user_story, only: [:show]

    # GET /scrum/user_stories/1
    # GET /scrum/user_stories/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user_story
      @user_story = UserStory.find(params[:id])
    end
  end
end
