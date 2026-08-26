module ApplicationHelper
  def field_required?(model_class, field)
    model_class.validators_on(field).any? { |validator| validator.is_a?(ActiveRecord::Validations::PresenceValidator) }
  end

  def field_optional?(model_class, field)
    !field_required?(model_class, field)
  end

  def n_field(form, field, clas: "field column is-12", label: nil, step: 0.10, placeholder: "$ 0.00", min: 0.10, max: nil, help: nil, data: {})
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label"
      end
      concat form.number_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", step: step, placeholder: placeholder, required: requiredd, min: min, max: max, data: data)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  def t_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, pattern: nil, title: nil, label_ghost: false, help: nil, data: {})
    requiredd =  field_required?(form.object.class, field)
    content_tag :div, class: clas do
      if label
        concat form.label field, "#{'* ' if requiredd}#{label}" || field.to_s.humanize, class: "label #{'is-ghost' if label_ghost}"
      end
      concat form.text_field(field, class: "input is-rounded #{'is-danger' if form.object.errors[field].any?}", required: requiredd, placeholder: placeholder, pattern: pattern, title: title, data: data)
      if form.object.errors[field].any?
        concat(content_tag(:p, class: "help is-danger") do
          form.object.errors.messages_for(field).each do |mss|
            concat "#{mss.humanize}. "
          end
        end)
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  ## password field
  def p_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, required: nil, help: nil)
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
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  def e_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, help: nil)
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
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  def a_field(form, field, clas: "field column is-12", label: nil, placeholder: nil, help: nil)
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
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  def s_field(form, field, options:, key: nil, value: nil, clas: "field column is-12", label: nil, help: nil)
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
      elsif help
        concat(content_tag(:p, class: "help") do
          concat help
        end)
      end
    end
  end

  def qr_code_svg(url, size: 4, fill: "fff", color: "000")
    return "" if url.blank?

    qrcode = RQRCode::QRCode.new(url)
    svg = qrcode.as_svg(
      offset: 0,
      color: color,
      fill: fill,
      shape_rendering: "crispEdges",
      module_size: size,
      use_path: true,
      viewbox: true
    )
    svg.sub(/\A<\?xml[^>]*\?>\s*/, "").html_safe
  end

  def render_mini_calendar_html(corp = nil)
    today = Date.today
    first_day = today.beginning_of_month
    last_day = today.end_of_month
    start_date = first_day.beginning_of_week(:monday)
    end_date = last_day.end_of_week(:monday)
    dates = (start_date..end_date).to_a

    month_name = (I18n.l(today, format: "%B %Y") rescue today.strftime("%B %Y")).titleize

    day_status_map = {}
    if corp.present?
      (first_day..last_day).each do |d|
        info = corp.available_slots_for_day(d) rescue nil
        if info.present? && info[:disponibles].to_i > 0
          day_status_map[d] = :open
        else
          day_status_map[d] = :busy
        end
      end
    end

    header = content_tag(:div, class: "cal-box-header") do
      content_tag(:h4, month_name, class: "cal-box-title")
    end

    days_header = content_tag(:div, class: "cal-box-weekdays") do
      safe_join(%w[L M M J V S D].map do |d|
        content_tag(:span, d, class: "cal-weekday")
      end)
    end

    grid = content_tag(:div, class: "cal-box-grid") do
      safe_join(dates.map do |d|
        is_current_month = d.month == today.month
        is_past = d < today
        unless is_current_month
          content_tag(:div, "", class: "cal-day-cell is-empty")
        else
          day_st = day_status_map[d] || :busy
          clas = [ "cal-day-cell" ]
          clas << "is-today" if d == today
          clas << "is-past" if is_past

          badge_class = if is_past
                          "cal-day-badge is-past"
          else
                          "cal-day-badge #{day_st == :open ? 'is-available' : 'is-occupied'}"
          end

          title_text = if is_past
                         "#{d.strftime('%d/%m')}: Pasado"
          else
                         "#{d.strftime('%d/%m')}: #{day_st == :open ? 'Disponible' : 'Ocupado / Sin cupo'}"
          end

          content_tag(:div, class: clas.join(" "), title: title_text) do
            content_tag(:span, d.day, class: badge_class)
          end
        end
      end)
    end


    content_tag(:div, safe_join([ header, days_header, grid ]), class: "calendar-main-box")
  end
end
