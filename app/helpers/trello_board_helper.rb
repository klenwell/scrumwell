module TrelloBoardHelper
  # rubocop: disable Rails/OutputSafety, Metrics/AbcSize
  def trello_board_icon(trello_board)
    scrummy_board = ScrumBoard.scrummy_trello_board?(trello_board)
    scrum_board = ScrumBoard.find_by(trello_board_id: trello_board.id)

    if scrummy_board && scrum_board.present?
      opts = { class: 'scrummy board text-success' }
      link_to scrum_icon, scrum_board_path(scrum_board), opts
    elsif scrummy_board
      format('<span class="scrummy">%s</span>', scrum_icon).html_safe
    else
      format('<span class="text-secondary">%s</span>', trello_icon).html_safe
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
