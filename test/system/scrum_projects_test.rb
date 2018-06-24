require "application_system_test_case"

class ScrumProjectsTest < ApplicationSystemTestCase
  setup do
    @scrum_project = scrum_projects(:one)
  end

  test "visiting the index" do
    visit scrum_projects_url
    assert_selector "h1", text: "Scrum Projects"
  end

  test "creating a Scrum project" do
    visit scrum_projects_url
    click_on "New Scrum Project"

    fill_in "Name", with: @scrum_project.name
    click_on "Create Scrum project"

    assert_text "Scrum project was successfully created"
    click_on "Back"
  end

  test "updating a Scrum project" do
    visit scrum_projects_url
    click_on "Edit", match: :first

    fill_in "Name", with: @scrum_project.name
    click_on "Update Scrum project"

    assert_text "Scrum project was successfully updated"
    click_on "Back"
  end

  test "destroying a Scrum project" do
    visit scrum_projects_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Scrum project was successfully destroyed"
  end
end
