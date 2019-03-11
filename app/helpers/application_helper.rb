module ApplicationHelper
  # For Material icon list: https://material.io/tools/icons/
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

  def import_icon
    material_icon.cloud_download
  end

  def abort_icon
    material_icon.clear
  end

  def bootstrap_datepicker(form, field, opts)
    placeholder = opts.fetch(:placeholder, 'YYYY-MM-DD')
    data = { 'provide' => 'datepicker', 'date-format' => 'yyyy-mm-dd', 'date-autoclose' => 'true' }
    form.text_field field, class: 'form-control', placeholder: placeholder, data: data
  end

  def as_decimal(value, opts={})
    value = format('%.1f', value) unless value.nil?
    or_na(value, opts)
  end

  def or_na(value, opts={})
    alt = opts.fetch(:alt, 'Not Available')
    value.presence || tag.span(alt, class: 'text-muted')
  end
end
