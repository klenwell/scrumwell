class ChartsController < ApplicationController
  # https://github.com/ankane/chartkick#say-goodbye-to-timeouts
  # rubocop: disable Metrics/AbcSize
  def scrum_board
    board = ScrumBoard.find(params[:id])
    completed_line = {
      name: 'Completed',
      data: board.completed_queues.map { |q| [q.ended_on, q.points] }
    }
    velocity_line = {
      name: 'Avg Velocity',
      data: board.completed_queues.map { |q| [q.ended_on, q.average_velocity] }
    }
    backlog_line = {
      name: 'Backlog',
      data: board.completed_queues.map { |q| [q.ended_on, q.backlog_points] }
    }
    wish_heap_line = {
      name: 'Wish Heap',
      data: board.completed_queues.map { |q| [q.ended_on, q.wish_heap_points] }
    }
    chart_data = [completed_line, velocity_line, backlog_line, wish_heap_line]
    render json: chart_data.chart_json
  end
  # rubocop: enable Metrics/AbcSize
end
