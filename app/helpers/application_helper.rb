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
    data = { 'provide' => 'datepicker', 'date-format' => 'yyyy-mm-dd', 'date-autoclose' => 'true' }
    form.text_field field, class: 'form-control', placeholder: placeholder, data: data
  end

  def or_na(value, opts={})
    alt = opts.fetch(:alt, 'Not Available')
    value.presence || tag.span(alt, class: 'text-muted')
  end

  # Source: https://stackoverflow.com/a/27209195/1093087
  # rubocop: disable Metrics/AbcSize
  def bootstrap_errors_for(object)
    return nil unless object.errors.any?

    tag.div(class: "card border-danger error-explanation mb-3") do
      concat(tag.div(class: "card-header bg-danger text-white") do
        f = '%s prohibited this %s from being saved:'
        concat format(f, pluralize(object.errors.count, "error"), object.class.name.downcase)
      end)
      concat(tag.div(class: "card-body") do
        concat(tag.ul(class: 'mb-0') do
          object.errors.full_messages.each do |msg|
            concat tag.li(msg)
          end
        end)
      end)
    end
  end
  # rubocop: enable Metrics/AbcSize
end
