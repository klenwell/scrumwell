class MockTrelloList
  attr_accessor :id, :name, :pos, :cards

  def initialize(params={})
    @name = params[:name]
    @id = params[:id] || @name.parameterize
    @pos = params[:pos] || rand(100_000..1_000_000)
    @cards = []
  end

  def add_card(card_params={})
    @cards << MockTrelloCard.new(card_params)
  end
end
