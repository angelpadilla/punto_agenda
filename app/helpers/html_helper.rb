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
end
