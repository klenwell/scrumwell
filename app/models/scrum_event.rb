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
  def old_data(key)
    return nil unless old_data?(key)
    trello_data['old'][key]
  end

  def old_data?(key)
    return false if trello_data['old'].nil?
    trello_data['old'].key? key
  end

  def creates_queue?
    action == 'created' && list?
  end

  def creates_story?
    action == 'created' && card?
  end

  def moves_story?
    action == 'changed_queue' && list?
  end

  def changes_story_status?
    return false unless card?
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
    return trello_data['card']['id'] if card?
    return trello_data['board']['id'] if board?
    return trello_data['list']['id'] if list?
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
