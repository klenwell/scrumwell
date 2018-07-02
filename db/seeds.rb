# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
SCRUMWELL_TRELLO_BOARD_ID = '5b26fe3ad86bfdbb5a8290b1'

scrumwell_backlog = ScrumBacklog.find_by_trello_board_id(SCRUMWELL_TRELLO_BOARD_ID)
if scrumwell_backlog
  puts 'Destroying existing Scrumwell backlog.'
  scrumwell_backlog.destroy
end

scrumwell_trello_board = TrelloService.board(SCRUMWELL_TRELLO_BOARD_ID)
scrumwell_backlog = ScrumBacklog.create_from_trello_board(scrumwell_trello_board)
puts format('Created Scrumwell backlog with %s sprints', scrumwell_backlog.sprints.count)
