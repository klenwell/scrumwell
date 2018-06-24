require 'test_helper'

module Scrum
  class ProjectsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @scrum_project = scrum_projects(:one)
    end

    test "should get index" do
      get scrum_projects_url
      assert_response :success
    end

    test "should get new" do
      get new_scrum_project_url
      assert_response :success
    end

    test "should create scrum_project" do
      assert_difference('ScrumProject.count') do
        post scrum_projects_url, params: { scrum_project: { name: @scrum_project.name } }
      end

      assert_redirected_to scrum_project_url(ScrumProject.last)
    end

    test "should show scrum_project" do
      get scrum_project_url(@scrum_project)
      assert_response :success
    end

    test "should get edit" do
      get edit_scrum_project_url(@scrum_project)
      assert_response :success
    end

    test "should update scrum_project" do
      patch scrum_project_url(@scrum_project),
            params: { scrum_project: { name: @scrum_project.name } }
      assert_redirected_to scrum_project_url(@scrum_project)
    end

    test "should destroy scrum_project" do
      assert_difference('ScrumProject.count', -1) do
        delete scrum_project_url(@scrum_project)
      end

      assert_redirected_to scrum_projects_url
    end
  end
end
