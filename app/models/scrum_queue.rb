class ScrumQueue < ApplicationRecord
  belongs_to :scrum_board
  
  #
  # Instance Methods
  #
  def trello_list
    TrelloService.list(trello_list_id)
  end

  def wish_heap?
    trello_list.name.downcase.include? 'wish'
  end

  def active_sprint?
    started_on <= Time.zone.today && ended_on >= Time.zone.today
  end
end
