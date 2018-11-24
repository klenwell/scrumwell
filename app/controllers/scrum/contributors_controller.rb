module Scrum
  class ContributorsController < ApplicationController
    before_action :authenticate
    before_action :set_contributor, only: [:show]

    # GET /scrum/contributors
    # GET /scrum/contributors.json
    def index
      @contributors = ScrumContributor.all

      respond_to do |format|
        format.html
        format.json { render json: @contributors }
      end
    end

    # GET /scrum/contributors/1
    # GET /scrum/contributors/1.json
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      @contributor = ScrumContributor.find(params[:id])
    end
  end
end
