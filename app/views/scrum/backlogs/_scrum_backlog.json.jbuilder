json.extract! scrum_backlog, :id, :trello_board_id, :trello_url, :name, :last_board_activity_at,
              :last_pulled_at, :created_at, :updated_at
json.url scrum_backlog_url(scrum_backlog, format: :json)
