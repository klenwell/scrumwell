module Trello
  class ImportsController < ApplicationController
    before_action :authenticate
    before_action :auth_scrum_masters
    before_action :set_import, only: [:show, :abort]

    # GET /trello/imports
    # GET /trello/imports.json
    def index
      @imports = TrelloImport.order(created_at: :desc)

      respond_to do |format|
        format.html
        format.json { render json: @imports }
      end
    end

    # GET /trello/imports/1
    # GET /trello/imports/1.json
    def show; end

    # PATCH /trello/imports/abort/1
    def abort
      return redirect_to trello_import_path(@import) unless @import.stuck?
      @import.abort_now
      redirect_to trello_import_path(@import), notice: 'Stuck import aborted.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_import
      @import = TrelloImport.find(params[:id])
    end
  end
end
