class UserStory < ApplicationRecord
  AGILE_TOOLS_PLUGIN_ID = '59d4ef8cfea15a55b0086614'.freeze

  belongs_to :queue, polymorphic: true, optional: true

  # Class Methods
  def self.update_or_create_from_trello_card(queue, trello_card)
    # Queue can be a WishHeap, ScrumBacklog, or ScrumSprintS
    story = UserStory.find_by(trello_card_id: trello_card.id)

    if story.present?
      story.queue = queue
      story.trello_pos = trello_card.pos
      story.trello_name = trello_card.name
      story.description = trello_card.desc
      story.points = UserStory.story_points_from_card(trello_card)
      story.last_imported_at = Time.now.utc
      story.save!
    else
      story = UserStory.create_from_trello_card(queue, trello_card)
    end

    story
  end

  def self.new_from_trello_card(trello_card)
    UserStory.new(trello_card_id: trello_card.id,
                  trello_short_url: trello_card.short_url,
                  trello_pos: trello_card.pos,
                  trello_name: trello_card.name,
                  description: trello_card.desc,
                  points: UserStory.story_points_from_card(trello_card),
                  last_activity_at: trello_card.last_activity_date,
                  last_imported_at: Time.zone.now)
  end

  def self.create_from_trello_card(queue, trello_card)
    story = UserStory.new_from_trello_card(trello_card)
    story.queue = queue
    story.save!
  end

  def self.user_story_card?(trello_card)
    non_story_titles = ['demo', 'retrospective']
    labels = trello_card.card_labels.map(&:downcase)

    return false if labels.include? 'scrum'
    return false if non_story_titles.include? trello_card.name.downcase
    true
  end

  def self.story_points_from_card(trello_card)
    agile_plugin = trello_card.plugin_data.find { |pd| pd.idPlugin == AGILE_TOOLS_PLUGIN_ID }
    agile_plugin.present? ? agile_plugin.value['points'].to_i : 0
  end

  # Instance Methods
  def public_title
    title.presence || trello_name
  end
end
