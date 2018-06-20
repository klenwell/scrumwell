namespace :trello do
  default_member = 'klenwell'
  scrumwell_board_id = '5b26fe3ad86bfdbb5a8290b1'
  agile_tools_plugin_id = '59d4ef8cfea15a55b0086614'

  desc "Counts story points in backlog info for given board"
  task :backlog, [:board_id] => :environment do |_, args|
    args.with_defaults(board_id: scrumwell_board_id)

    board = TrelloService.board(args[:board_id])
    backlog = board.lists.detect { |list| list.name.downcase.include? 'backlog' }

    abort "Backlog list not found for board #{board.name}." unless backlog

    backlog_story_points = 0
    backlog.cards.each do |card|
      card_title = card.name
      agile_plugin = card.plugin_data.detect { |d| d.idPlugin == agile_tools_plugin_id }
      story_points = agile_plugin.present? ? agile_plugin.value['points'] : 0
      backlog_story_points += story_points
      puts format('[%d] %s', story_points, card_title)
    end

    puts format("Backlog points for board %s: %d", board.name, backlog_story_points)
  end

  desc "Lists boards ids for given member"
  task :boards, [:member_name] => :environment do |_, args|
    args.with_defaults(member_name: default_member)

    member = TrelloService.user(args[:member_name])

    board_map = {}
    member.boards.each do |board|
      board_map[board.name] = board.id
    end

    pp board_map
    puts format("%s has %d boards", member.username, board_map.keys.count)
  end
end
