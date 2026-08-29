module HtmlHelper
  # stat card box
  def stat_card(counter, body, icon: nil, inverted: true, wrap_class: "", box_class: "", currency: false, link: nil)
    content_tag :div, class: "column #{wrap_class}" do
      concat(content_tag :div, class: "box stat_card #{box_class}" do
        concat(content_tag :div, class: "stat_icon" do
          if icon
            image_tag "#{icon}.svg", class: "invert" if inverted
          else
            image_tag "dollar.svg", class: "invert" if inverted
          end
        end)
        concat(content_tag :div, class: "stat_val" do
          if link
            link_to (currency ? number_to_currency(counter) : counter.to_s), link, class: "stat_val_link"
          else
            currency ? number_to_currency(counter) : counter.to_s
          end
        end)
        concat(content_tag :div, class: "stat_label" do
          body
        end)
      end)
    end
  end

  def expandable_box(title, icon: nil, inverted_icon: false, classes: "mt-4", active: false, &block)
    content_tag(:div, class: "box expandable #{classes} #{'is_active' if active}") do
      header = content_tag(:div, class: "box_header") do
        title_header = content_tag(:h2) do
          title_content = []

          if icon.present?
            icon_classes = ["mr-2"]
            icon_classes << "invert" if inverted_icon

            title_content << content_tag(:span, class: "icon #{icon_classes.join(' ')}") do
              image_tag(icon, alt: title)
            end
          end

          title_content << title.to_s

          safe_join(title_content)
        end

        toggle_icon = content_tag(:span, class: "icon toggle_icon") do
          image_tag("down.svg", alt: "toggle icon", class: "invert")
        end

        safe_join([title_header, toggle_icon])
      end

      body = content_tag(:div, capture(&block), class: "box_content")

      safe_join([header, body])
    end
  end
end
