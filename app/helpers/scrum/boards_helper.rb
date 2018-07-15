module Scrum::BoardsHelper
  def trello_url_link(scrum_board, opts={})
    alt = opts.fetch('alt', 'Not Available')

    if scrum_board.trello_url
      link_to scrum_board.trello_url, scrum_board.trello_url
    else
      tag.span alt, class: 'text-muted'
    end
  end
end
