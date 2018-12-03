# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Scrumwell Trello Board
SCRUMWELL_TRELLO_BOARD_ID = '5b26fe3ad86bfdbb5a8290b1'

def seed_scrumwell_trello_board
  scrumwell_board = ScrumBoard.find_by(trello_board_id: SCRUMWELL_TRELLO_BOARD_ID)
  if scrumwell_board
    puts 'Destroying existing Scrumwell board.'
    scrumwell_board.destroy
  end

  scrumwell_trello_board = TrelloService.board(SCRUMWELL_TRELLO_BOARD_ID)
  scrumwell_board = ScrumBoard.reconstruct_from_trello_board_actions(scrumwell_trello_board)

  puts format('Created board %s with %s sprints',
              scrumwell_board.name,
              scrumwell_board.completed_queues.count)
end

# Main
seed_scrumwell_trello_board
