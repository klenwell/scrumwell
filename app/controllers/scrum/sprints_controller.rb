module Scrum
  class SprintsController < ApplicationController
    # GET /scrum_sprints
    # GET /scrum_sprints.json
    def index
      @scrum_sprints = ScrumSprint.all
    end
  end
end
