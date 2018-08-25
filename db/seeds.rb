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
  scrumwell_board = ScrumBoard.create_from_trello_board(scrumwell_trello_board)

  puts format('Created board %s with %s sprints',
              scrumwell_board.name,
              scrumwell_board.sprints.count)
end

# Sample Non-Trello Board
def seed_sample_non_trello_board
  board_name = 'Sample Non-Trello Board'
  sprint_data = [
    # [:name, :started_on, :ended_on, :story_points_committed, :story_points_completed,
    #  :average_story_size, :backlog_story_points, :backlog_stories_count,
    #  :wish_heap_stories_count, :notes]
    ['20180314', '2/28/2018',' 3/14/2018', 10, 10, 3.3, 54, 30, 30, 'First sprint.'],
    ['20180328', '3/14/2018', '3/28/2018', 12, 8, 1.6, 52, 30, 30, ''],
    ['20180411', '3/28/2018', '4/11/2018', 20, 21, 2.6, 63, 30, 37, ''],
    ['20180425', '4/11/2018',	'4/25/2018', 14, 14, 1.3, 64, 28, 47, ''],
    ['20180509', '4/25/2018',	'5/9/2018', 14, 12, 1.0, 61, 27, 54, ''],
    ['20180523', '5/9/2018',	'5/23/2018', 16, 13, 2.6, 59, 27, 60, '']
  ]

  existing_board = ScrumBoard.find_by(local_name: board_name)
  if existing_board
    puts "Destroying existing #{board_name} board."
    existing_board.destroy
  end

  board = ScrumBoard.create!(local_name: board_name)

  sprint_data.each do |row|
    start_m, start_d, start_y = row[1].split('/')
    end_m, end_d, end_y = row[2].split('/')
    sprint = ScrumSprint.new(scrum_board_id: board.id,
                             name: row[0],
                             started_on: Date.new(start_y.to_i, start_m.to_i, start_d.to_i),
                             ended_on: Date.new(end_y.to_i, end_m.to_i, end_d.to_i),
                             story_points_committed: row[3],
                             story_points_completed: row[4],
                             average_story_size: row[5],
                             backlog_story_points: row[6],
                             backlog_stories_count: row[7],
                             wish_heap_stories_count: row[8],
                             notes: row[9])

    sprint.save!
  end

  board.reload
  puts "Created board #{board.name} with #{board.sprints.count} sprints"
end

# Main
seed_scrumwell_trello_board
seed_sample_non_trello_board
