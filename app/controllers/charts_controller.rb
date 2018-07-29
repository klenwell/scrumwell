class ChartsController < ApplicationController
  # https://github.com/ankane/chartkick#say-goodbye-to-timeouts
  # rubocop: disable Metrics/AbcSize
  def scrum_board
    board = ScrumBoard.find(params[:id])
    completed_line = {
      name: 'Completed',
      data: board.sprints.reverse.map { |s| [s.ended_on, s.story_points_completed] }
    }
    velocity_line = {
      name: 'Avg Velocity',
      data: board.sprints.map { |s| [s.ended_on, s.average_velocity] }
    }
    backlog_line = {
      name: 'Backlog',
      data: board.sprints.map { |s| [s.ended_on, s.backlog_story_points] }
    }
    wish_heap_line = {
      name: 'Wish Heap',
      data: board.sprints.map { |s| [s.ended_on, s.wish_heap_story_points] }
    }
    chart_data = [completed_line, velocity_line, backlog_line, wish_heap_line]
    render json: chart_data.chart_json
  end
  # rubocop: enable Metrics/AbcSize
end
