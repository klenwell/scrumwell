class ScrumQueue < ApplicationRecord
  belongs_to :scrum_board

  #
  # Instance Methods
  #
  def trello_list
    TrelloService.list(trello_list_id)
  end

  def wish_heap?
    # Preferred version:
    return true if name.downcase.include?('wish heap')

    # Legacy version:
    name.downcase.include?('wish')
  end

  def project_backlog?
    # Preferred version:
    return true if name.downcase.include?('project backlog')

    # Legacy version:
    name.downcase.include?('backlog')
  end

  def sprint_backlog?
    # Preferred version:
    return true if name.downcase.include?('sprint backlog')

    # Legacy version:
    name.downcase.include?('current')
  end

  def active_sprint?
    name.downcase.include?('completed') &&
      started_on <= Time.zone.today && ended_on >= Time.zone.today
  end
end
