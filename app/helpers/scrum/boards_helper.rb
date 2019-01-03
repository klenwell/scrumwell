module Scrum::BoardsHelper
  def trello_url_link(scrum_board, opts={})
    alt = opts.fetch('alt', 'Not Available')

    if scrum_board.trello_url
      link_to scrum_board.trello_url, scrum_board.trello_url
    else
      tag.span alt, class: 'text-muted'
    end
  end

  def scrum_board_nav_tab_class(tab_label)
    tab_label = tab_label.downcase
    @tab == tab_label ? 'active' : 'inactive'
  end
end
