module ApplicationHelper
  def display_field(value)
    if value.blank? || value == "Not found"
      content_tag(:em, "Not found", class: "not-found")
    else
      value
    end
  end

  def field_status(value)
    if value.blank? || value == "Not found"
      "field-empty"
    else
      "field-found"
    end
  end
end
