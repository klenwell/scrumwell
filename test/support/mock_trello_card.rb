class MockTrelloCard
  attr_accessor :id, :name, :pos, :desc, :short_url, :last_activity_date, :card_labels,
                :plugin_data

  # rubocop: disable Metrics/AbcSize
  def initialize(params={})
    @name = params[:name]
    @id = params[:id] || @name.parameterize
    @pos = params[:pos] || rand(100_000..1_000_000)
    @desc = params[:desc]
    @last_activity_date = Time.zone.now
    @card_labels = []
    @plugin_data = []

    # Simulate Agile Tools plugin.
    agile_tools_plugin = OpenStruct.new(idPlugin: agile_tools_plugin_id, value: {})
    @plugin_data << agile_tools_plugin

    # Points?
    self.story_points = params[:points] if params[:points]
  end
  # rubocop: enable Metrics/AbcSize

  def agile_tools_plugin_id
    ScrumStory::AGILE_TOOLS_PLUGIN_ID
  end

  def story_points=(points)
    agile_tools_plugin = @plugin_data.find { |pd| pd.idPlugin == agile_tools_plugin_id }
    agile_tools_plugin.value['points'] = points.to_s
  end
end
