class TrelloController < ApplicationController
  def boards_index
    @trello = TrelloService.new
    active_boards = @trello.public_boards.keep_if { |b| b.last_activity_date.present? }
    @boards = active_boards.sort_by(&:last_activity_date).reverse
  end

  def orgs_index
    @trello = TrelloService.new
  end

  def orgs_boards_index
    @org = TrelloService.org(params[:id])
    active_boards = @org.boards.keep_if { |b| b.last_activity_date.present? }
    @boards = active_boards.sort_by(&:last_activity_date).reverse
  end
end
