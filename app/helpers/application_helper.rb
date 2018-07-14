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

  def bootstrap_datepicker(form, field, opts)
    placeholder = opts.fetch(:placeholder, 'YYYY-MM-DD')
    data = {'provide' => 'datepicker', 'date-format' => 'yyyy-mm-dd', 'date-autoclose' => 'true'}
    form.text_field field, class: 'form-control', placeholder: placeholder, data: data
  end
end
