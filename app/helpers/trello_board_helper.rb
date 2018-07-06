module TrelloBoardHelper
  # rubocop: disable Rails/OutputSafety, Metrics/AbcSize
  def trello_board_icon(board)
    scrummy_board = ScrumBacklog.scrummy_trello_board?(board)
    backlog = ScrumBacklog.find_by(trello_board_id: board.id)

    if scrummy_board && backlog.present?
      opts = { class: 'scrummy backlog text-success' }
      link_to material_icon.bubble_chart, scrum_backlog_path(backlog), opts
    elsif scrummy_board
      format('<span class="scrummy">%s</span>', material_icon.bubble_chart).html_safe
    else
      format('<span class="text-secondary">%s</span>', material_icon.table_chart).html_safe
    end
  end
  # rubocop: enable Rails/OutputSafety, Metrics/AbcSize

  def board_org_link(board)
    if board.organization_id
      link_to board.organization.display_name, board.organization.url
    else
      'N/A'
    end
  end
end
