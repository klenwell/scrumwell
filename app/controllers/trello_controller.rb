class TrelloController < ApplicationController
  def boards_index
    @trello = TrelloService.new
  end
end
