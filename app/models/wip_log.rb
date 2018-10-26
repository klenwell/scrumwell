class WipLog < ApplicationRecord
  ## Associations
  belongs_to :scrum_event

  ## Aliases
  alias_attribute :event, :scrum_event

  #
  # Instance Methods
  #
  def story?
    event.eventable.is_a? ScrumStory
  end

  def story
    return nil unless story?
    event.eventable
  end

  def queue
    list_id = event.trello_data.dig('list', 'id')
    return nil unless list_id
    ScrumQueue.find_by(trello_list_id: list_id)
  end

  def new_queue
    return queue if event.creates_story? || event.reopens_story?
    return after_queue if event.moves_story?
    nil if event.closes_story?
  end

  def old_queue
    return nil if event.creates_story? || event.reopens_story?
    return before_queue if event.moves_story?
    queue if event.closes_story?
  end

  def before_queue
    list_before_id = event.trello_data.dig('listBefore', 'id')
    return nil unless list_before_id
    ScrumQueue.find_by(trello_list_id: list_before_id)
  end

  def after_queue
    list_after_id = event.trello_data.dig('listAfter', 'id')
    return nil unless list_after_id
    ScrumQueue.find_by(trello_list_id: list_after_id)
  end

  def point_change
    return 0 unless story.try(:estimated_points)
    story.estimated_points
  end
end
