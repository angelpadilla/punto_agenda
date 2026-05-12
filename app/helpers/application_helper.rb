module ApplicationHelper
  def field_required?(model_class, field)
    model_class.validators_on(field).any? { |validator| validator.is_a?(ActiveRecord::Validations::PresenceValidator) }
  end

  def field_optional?(model_class, field)
    !field_required?(model_class, field)
  end

  def n_field(form, field, clas: "field column is-12", label: nil, step: 0.10, placeholder: "$ 0.00", min: 0.10, max: nil)
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat form.number_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", step: step, placeholder: placeholder, required: requiredd, min: min, max: max)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end

  def t_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, pattern: nil, title: nil, label_ghost: false)
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label #{'is-ghost' if label_ghost}"
      end
      concat form.text_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", required: requiredd, placeholder: placeholder, pattern: pattern, title: title)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end

  ## password field
  def p_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, required: nil)
    requiredd =  field_required?(form.object.class, field) || required
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat form.password_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", required: requiredd, placeholder: placeholder)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end

  def e_field(form, field, clas: "field column is-12", label: nil, placeholder: nil)
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat form.email_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", required: requiredd, placeholder: placeholder)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end

  def a_field(form, field, clas: "field column is-12", label: nil, placeholder: nil)
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat form.text_area(field, class: "textarea is-rounded #{'is-danger' if form.object.errors[field].any?}", required: requiredd, placeholder: placeholder)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end

  def s_field(form, field, options:, key: nil, value: nil, clas: "field column is-12", label: nil)
    unless options.is_a?(Array)
      ## en este caso validar que key y value no sean nulos
      raise ArgumentError, "Key and value must be provided for non-array options" if key.nil? || value.nil?

      options = options.map do |o|
        [ o.send(value), o.send(key) ]
      end
    end
    ## validar si options es un array o objeto de ActiveRecord para usar options_for_select o collection_select
    options = options.is_a?(Array) ? options : options.map { |o| [ o.send(value), o.send(key) ] }

    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat(content_tag(:div, class: "select is-rounded #{'is-danger' if form.object.errors[field].any?}") do
        form.select(field, options_for_select(options, form.object.send(field) ? form.object.send(field) : value), { prompt: "Selecciona", required: requiredd }, {})
      end)

      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      end
    end
  end
end
