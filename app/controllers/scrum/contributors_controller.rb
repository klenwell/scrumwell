module Scrum
  class ContributorsController < ApplicationController
    before_action :authenticate
    before_action :auth_scrum_masters
    before_action :set_contributor, only: [:show]
    before_action :set_scrum_contributor_tab, only: [:show]

    # GET /scrum/contributors
    # GET /scrum/contributors.json
    def index
      @contributors = ScrumContributor.all.sort_by(&:avg_capacity).reverse

      respond_to do |format|
        format.html
        format.json { render json: @contributors }
      end
    end

    # GET /scrum/contributors/1
    # GET /scrum/contributors/1/sprints
    # GET /scrum/contributors/1/stories
    def show; end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_contributor
      @contributor = ScrumContributor.find(params[:id])
    end

    def set_scrum_contributor_tab
      valid_tabs = ['sprints', 'stories']
      @tab = request.fullpath.split('/').last
      @tab = valid_tabs.first unless valid_tabs.include? @tab
    end
  end
end
