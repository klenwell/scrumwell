class ScrumEvent < ApplicationRecord
  ## Associations
  belongs_to :eventable, polymorphic: true, optional: true
  belongs_to :scrum_board
  belongs_to :scrum_contributor, primary_key: :trello_member_id, foreign_key: :trello_member_id,
                                 inverse_of: :scrum_events, optional:true
  has_one :wip_log, dependent: :destroy

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
      trello_member_id: trello_action.member_creator_id,
      trello_data: trello_action.data,
      occurred_at: trello_action.date
    )
  end

  #
  # Instance Methods
  #
  def trello_action
    # Gets action data from Trello
    Trello::Action.find(trello_id)
  end

  def wip?
    return false if card? && deletes_story?
    creates_story? || moves_story? || changes_story_status?
  end

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

  def creates_board?
    action == 'created' && board?
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

  def reopens_story?
    action == 'reopened' && card?
  end

  def closes_story?
    close_actions = ['deleted', 'closed']
    card? && close_actions.include?(action)
  end

  def deletes_story?
    action == 'deleted' && card?
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
    trello_list = TrelloService.list(trello_list_id)

    # Queue may already exist. See ScrumBoard.reconstruct_from_trello_board_actions.
    queue = ScrumQueue.find_or_create_from_trello_list(board, trello_list)

    update!(eventable: queue)
    queue
  end

  def create_story_for_board(board)
    queue = board.queue_by_trello_id(trello_list_id)

    story = ScrumStory.create!(
      scrum_board: board,
      scrum_queue: queue,
      trello_card_id: trello_card_id,
      title: trello_data.dig('card', 'name'),
      created_at: occurred_at
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

  def queue
    list_id = trello_data.dig('list', 'id')
    return nil unless list_id
    ScrumQueue.find_by(trello_list_id: list_id)
  end

  def new_queue
    return queue if creates_story? || reopens_story?
    return after_queue if moves_story?
    nil if closes_story?
  end

  def old_queue
    return nil if creates_story? || reopens_story?
    return before_queue if moves_story?
    queue if closes_story?
  end

  def before_queue
    list_before_id = trello_data.dig('listBefore', 'id')
    return nil unless list_before_id
    ScrumQueue.find_by(trello_list_id: list_before_id)
  end

  def after_queue
    list_after_id = trello_data.dig('listAfter', 'id')
    return nil unless list_after_id
    ScrumQueue.find_by(trello_list_id: list_after_id)
  end

  def to_stdout
    f = '#<ScrumEvent id=%s trello_type=%s action=%s queues:%s->%s occurred_at=%s>'
    format(f, id, trello_type, action, old_queue.try(:name), new_queue.try(:name), occurred_at)
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
    return :created if trello_type == 'createBoard'

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
