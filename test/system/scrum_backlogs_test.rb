require "application_system_test_case"

class ScrumBacklogsTest < ApplicationSystemTestCase
  setup do
    @scrum_backlog = scrum_backlogs(:one)
  end

  test "visiting the index" do
    visit scrum_backlogs_url
    assert_selector "h1", text: "Scrum Backlogs"
  end

  test "creating a Scrum backlog" do
    visit scrum_backlogs_url
    click_on "New Scrum Backlog"

    fill_in "Last Board Activity At", with: @scrum_backlog.last_board_activity_at
    fill_in "Last Pulled At", with: @scrum_backlog.last_pulled_at
    fill_in "Name", with: @scrum_backlog.name
    fill_in "Trello Board", with: @scrum_backlog.trello_board_id
    fill_in "Trello Url", with: @scrum_backlog.trello_url
    click_on "Create Scrum backlog"

    assert_text "Scrum backlog was successfully created"
    click_on "Back"
  end

  test "updating a Scrum backlog" do
    visit scrum_backlogs_url
    click_on "Edit", match: :first

    fill_in "Last Board Activity At", with: @scrum_backlog.last_board_activity_at
    fill_in "Last Pulled At", with: @scrum_backlog.last_pulled_at
    fill_in "Name", with: @scrum_backlog.name
    fill_in "Trello Board", with: @scrum_backlog.trello_board_id
    fill_in "Trello Url", with: @scrum_backlog.trello_url
    click_on "Update Scrum backlog"

    assert_text "Scrum backlog was successfully updated"
    click_on "Back"
  end

  test "destroying a Scrum backlog" do
    visit scrum_backlogs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Scrum backlog was successfully destroyed"
  end
end
