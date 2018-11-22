class Contributor < ApplicationRecord
  has_many :contributions, dependent: :destroy
  has_many :scrum_stories, through: :contributions

  def create_from_trello_member(trello_member)
    Contributor.create!(
      trello_member_id: trello_member.id,
      trello_url: trello_member.url,
      trello_avatar_url: trello_member.avatar_url,

      username: trello_member.username,
      full_name: trello_member.full_name,
      email: trello_member.email
    )
  end

  def self.find_or_create_by_trello_member_id(member_id)
    contributor = find_by(trello_member_id: member_id)
    return contributor if contributor.present?

    trello_member = TrelloService.member(member_id)
    return nil if trello_member.nil?

    Contributor.create_from_trello_member(trello_member)
  end
end
