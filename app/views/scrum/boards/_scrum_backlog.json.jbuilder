json.extract! scrum_board, :id, :trello_board_id, :trello_url, :name, :last_board_activity_at,
              :last_imported_at, :created_at, :updated_at
json.url scrum_board_url(scrum_board, format: :json)
