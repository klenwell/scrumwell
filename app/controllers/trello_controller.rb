class TrelloController < ApplicationController
  def boards_index
    @trello = TrelloService.new
    @active_boards = @trello.boards.keep_if{ |b| b.last_activity_date.present? }
  end
end
