module Scrum::SprintsHelper
  def format_avg_velocity(sprint)
    return '—' if sprint.current?
    return 'N/A' if sprint.average_velocity.nil?
    format('%.1f', sprint.average_velocity)
  end
end
