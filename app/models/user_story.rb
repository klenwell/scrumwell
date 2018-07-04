class UserStory < ApplicationRecord
  AGILE_TOOLS_PLUGIN_ID = '59d4ef8cfea15a55b0086614'.freeze

  belongs_to :scrum_sprint, optional: true

  alias_attribute :sprint, :scrum_sprint

  # Class Methods
  def self.update_or_create_from_trello_card(scrum_sprint, trello_card)
    story = UserStory.find_by(trello_card_id: trello_card.id)

    if story.present?
      story.trello_pos = trello_card.pos
      story.trello_name = trello_card.name
      story.description = trello_card.desc
      story.story_points = UserStory.story_points_from_card(trello_card)
      story.last_pulled_at = Time.now.utc
      story.save!
    else
      story = UserStory.create_from_trello_card(scrum_sprint, trello_card)
    end

    story
  end

  def self.create_from_trello_card(scrum_sprint, trello_card)
    UserStory.create(scrum_sprint_id: scrum_sprint.id,
                     trello_card_id: trello_card.id,
                     trello_short_url: trello_card.short_url,
                     trello_pos: trello_card.pos,
                     trello_name: trello_card.name,
                     description: trello_card.desc,
                     points: UserStory.story_points_from_card(trello_card),
                     last_activity_at: trello_card.last_activity_date,
                     last_pulled_at: Time.zone.now)
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
    title.present? ? title : trello_name
  end
end
