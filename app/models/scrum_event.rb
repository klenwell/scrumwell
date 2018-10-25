class ScrumEvent < ApplicationRecord
  ## Associations
  belongs_to :eventable, polymorphic: true, optional: true
  belongs_to :scrum_board

  ## Callbacks
  before_create :categorize

  #
  # Instance Methods
  #
  def self.create_from_trello_board_event(scrum_board, trello_action)
    ScrumEvent.create!(
      scrum_board: scrum_board,
      trello_id: trello_action.id,
      trello_type: trello_action.type,
      trello_data: trello_action.data,
      occurred_at: trello_action.date
    )
  end

  #
  # Instance Methods
  #
  def trello_data?(key)
    trello_data.key? key
  end

  def old_data?(key)
    return false unless trello_data?('old')
    trello_data['old'].key? key
  end

  def old_data(key)
    return nil unless old_data?(key)
    trello_data['old'][key]
  end

  def creates_queue?
    action == 'created' && list?
  end

  def creates_story?
    action == 'created' && card?
  end

  def moves_story?
    action == 'changed_queue' && card?
  end

  def changes_story_status?
    status_actions = ['deleted', 'closed', 'reopened']
    card? && status_actions.include?(action)
  end

  def card?
    trello_object == 'card'
  end

  def list?
    trello_object == 'list'
  end

  def board?
    trello_object == 'board'
  end

  def trello_object_id
    return trello_board_id if board?
    return trello_card_id if card?
    return trello_list_id if list?
  end

  def trello_board_id
    return nil unless trello_data?('board')
    trello_data['board']['id']
  end

  def trello_list_id
    return nil unless trello_data?('list')
    trello_data['list']['id']
  end

  def trello_card_id
    return nil unless trello_data?('card')
    trello_data['card']['id']
  end

  ## WIP events
  def create_queue_for_board(board)
    queue = ScrumQueue.new(
      scrum_board: board,
      trello_list_id: trello_list_id
    )

    # Use current Trello list name rather than original event name as queue could have
    # been renamed.
    queue.name = queue.trello_list.name
    queue.save!

    update!(eventable: queue)
    queue
  end

  def create_story_for_board(board)
    queue = board.queue_by_trello_id(trello_list_id)

    story = ScrumStory.create!(
      scrum_board: board,
      scrum_queue: queue,
      trello_card_id: trello_card_id,
      title: trello_data.dig('card', 'name')
    )

    update!(eventable: story)
    story
  end

  def move_story
    list_id = trello_data['listAfter']['id']
    raise 'listAfter id not found' unless list_id

    story = ScrumStory.find_by(trello_card_id: trello_card_id)
    new_queue = ScrumQueue.find_by(trello_list_id: list_id)
    story.change_queue(new_queue, event: self)

    update!(eventable: story)
    story
  end

  def update_story_status
    story = ScrumStory.find_by(trello_card_id: trello_card_id)

    return nil unless story

    if ['closed', 'deleted'].include? action
      story.close
    elsif action == 'reopened'
      story.reopen(event: self)
    end

    update!(eventable: story)
    story
  end

  private

  def categorize
    self.trello_object = categorize_trello_object
    self.action = categorize_action
  end

  def categorize_trello_object
    type_object_map = {
      board: ['addMemberToBoard', 'addToOrganizationBoard', 'createBoard', 'updateBoard'],
      card: ['addMemberToCard', 'convertToCardFromCheckItem', 'copyCard', 'createCard',
             'deleteCard', 'updateCard'],
      checklist: ['addChecklistToCard', 'removeChecklistFromCard', 'updateCheckItemStateOnCard',
                  'updateChecklist'],
      comment: ['commentCard'],
      list: ['createList', 'updateList'],
      plugin: ['enablePlugin']
    }

    type_object_map.each do |obj, types|
      return obj if types.include?(trello_type)
    end

    nil
  end

  # rubocop: disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def categorize_action
    card_creation_actions = ['convertToCardFromCheckItem', 'copyCard', 'createCard']

    return :created if card_creation_actions.include? trello_type
    return :created if trello_type == 'createList'

    return :changed_queue if card? && old_data?('idList')
    return :changed_due_date if card? && old_data?('due')
    return :changed_description if card? && old_data?('desc')

    return :renamed if old_data?('name')

    return :repositioned if card? && old_data?('pos')
    return :repositioned if list? && old_data?('pos')

    return :completed if old_data('dueComplete') == false
    return :deleted if trello_type == 'deleteCard'
    return :closed if old_data('closed') == false
    return :reopened if old_data('closed') == true

    return :added_member if trello_type == 'addMemberToCard'

    return trello_object if [:board, :checklist, :comment, :plugin].include? trello_object

    nil
  end
  # rubocop: enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
