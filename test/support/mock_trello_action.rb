class MockTrelloAction
  attr_accessor :id, :type, :member_creator_id, :date, :data

  def initialize(params={})
    @id = params[:id]
    @type = params[:type]
    @member_creator_id = params[:member_creator_id]
    @date = params[:date]
    @data = params[:data] || { mock: true }
  end
end
