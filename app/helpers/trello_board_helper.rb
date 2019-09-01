module TrelloBoardHelper
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

  def board_org_link(board)
    if board.organization_id
      link_to board.organization.display_name, board.organization.url
    else
      tag.span('N/A', class: 'text-muted')
    end
  end

  def trello_board_import_link(trello_board)
    return '' unless ScrumBoard.scrummy_trello_board?(trello_board)
    return '' if ScrumBoard.find_by(trello_board_id: trello_board.id).present?
    link_to import_icon, trello_board_import_path(id: trello_board.id),
            title: 'import', method: :post
  end

  def trello_board_navbar_class(nav_label)
    action = params[:action]
    action = 'index' if action == 'all'
    action == nav_label ? 'active' : 'inactive'
  end
end
