module Scrum::QueuesHelper
  def scrum_sprint_form_url(queue)
    if queue.new_record?
      scrum_board_queues_path(queue.scrum_board, queue)
    else
      queue
    end
  end

  def import_completed_sprint_button(sprint)
    return '' unless sprint.over?
    link_to import_icon, import_queue_path(sprint), remote: true, data: { type: :html },
                                                    class: 'import-sprint'
  end
end
