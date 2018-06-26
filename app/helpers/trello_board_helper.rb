module TrelloBoardHelper
  def board_org_link(board)
    if @board.organization_id
      link_to @board.organization.display_name, @board.organization.url
    else
      'N/A'
    end
  end
end
