require 'trello'

# Get API key and test token: https://trello.com/app-key
Trello.configure do |config|
  config.developer_public_key = Rails.application.credentials.trello_app_key
  config.member_token = Rails.application.credentials.trello_member_token
end
