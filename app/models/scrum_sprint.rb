class ScrumSprint < ApplicationRecord
  belongs_to :scrum_backlog

  alias_attribute :backlog, :scrum_backlog

  #
  # Class Methods
  #
  def self.sprinty_trello_list?(trello_list)
    trello_list.name.downcase.include? 'complete'
  end

  def self.create_from_trello_list(scrum_backlog, trello_list)
    # https://stackoverflow.com/a/12858147/1093087
    name = trello_list.name.delete("^0-9")
    ends_on = Date.parse(name)
    starts_on = ends_on - ScrumBacklog::DEFAULT_SPRINT_DURATION

    ScrumSprint.create(scrum_backlog_id: scrum_backlog.id,
                       trello_list_id: trello_list.id,
                       trello_pos: trello_list.pos,
                       name: name,
                       started_on: starts_on,
                       ended_on: ends_on,
                       last_pulled_at: Time.now.utc)
  end

  #
  # Instance Methods
  #
  def over?
    Date.today < ended_on
  end

  private
end
