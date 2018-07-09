module ApplicationHelper
  def scrum_icon
    material_icon.bubble_chart
  end

  def trello_icon
    material_icon.view_week
  end

  def show_icon
    material_icon.pageview
  end

  def edit_icon
    material_icon.edit
  end
end
