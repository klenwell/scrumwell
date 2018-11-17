class MockTrelloAction
  attr_accessor :id, :type, :date, :data

  def initialize(params={})
    @id = params[:id]
    @type = params[:type]
    @date = params[:date]
    @data = params[:data] || { mock: true }
  end
end
