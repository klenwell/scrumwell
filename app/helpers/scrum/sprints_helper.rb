module Scrum::SprintsHelper
  def format_avg_velocity(sprint)
    return '—' if sprint.current?
    return 'N/A' if sprint.average_velocity.nil?
    format('%.1f', sprint.average_velocity)
  end

  def scrum_sprint_form_url(scrum_sprint)
    if scrum_sprint.new_record?
      scrum_board_sprints_path(scrum_sprint.scrum_board, scrum_sprint)
    else
      scrum_sprint
    end
  end

  def import_completed_sprint_button(sprint)
    return '' unless sprint.over?
    link_to import_icon, import_sprint_path(sprint), remote: true
  end
end
