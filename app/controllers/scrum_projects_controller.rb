class ScrumProjectsController < ApplicationController
  before_action :set_scrum_project, only: [:show, :edit, :update, :destroy]

  # GET /scrum_projects
  # GET /scrum_projects.json
  def index
    @scrum_projects = ScrumProject.all
  end

  # GET /scrum_projects/1
  # GET /scrum_projects/1.json
  def show; end

  # GET /scrum_projects/new
  def new
    @scrum_project = ScrumProject.new
  end

  # GET /scrum_projects/1/edit
  def edit; end

  # POST /scrum_projects
  # POST /scrum_projects.json
  def create
    @scrum_project = ScrumProject.new(scrum_project_params)

    respond_to do |format|
      if @scrum_project.save
        format.html {
          redirect_to @scrum_project,
                      notice: 'Scrum project was successfully created.'
        }
        format.json { render :show, status: :created, location: @scrum_project }
      else
        format.html { render :new }
        format.json { render json: @scrum_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scrum_projects/1
  # PATCH/PUT /scrum_projects/1.json
  def update
    respond_to do |format|
      if @scrum_project.update(scrum_project_params)
        format.html {
          redirect_to @scrum_project,
                      notice: 'Scrum project was successfully updated.'
        }
        format.json { render :show, status: :ok, location: @scrum_project }
      else
        format.html { render :edit }
        format.json { render json: @scrum_project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scrum_projects/1
  # DELETE /scrum_projects/1.json
  def destroy
    @scrum_project.destroy
    respond_to do |format|
      format.html {
        redirect_to scrum_projects_url,
                    notice: 'Scrum project was successfully destroyed.'
      }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_scrum_project
    @scrum_project = ScrumProject.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def scrum_project_params
    params.require(:scrum_project).permit(:name)
  end
end
