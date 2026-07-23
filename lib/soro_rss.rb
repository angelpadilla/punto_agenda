class SoroRss
  DEFAULT_FEED_URL = "https://app.trysoro.com/api/rss/7cd01f4d-993b-4a20-85d9-3d8cf5f679fb".freeze
  SOURCE_NAME = "Soro AI".freeze

  def self.run
    response = HTTP.get(DEFAULT_FEED_URL)
    return self.failure("Error descargando RSS: #{response.status}") unless response.status.success?

    items = self.parse_items(response.to_s)

    result = {
      success: true,
      feed_url: DEFAULT_FEED_URL,
      total_items: items.size,
      created: 0,
      duplicates: 0,
      errors: 0,
      error_details: []
    }

    items.each_with_index do |item, index|
      outcome = import_item(item)

      case outcome[:status]
      when :created
        result[:created] += 1
      when :duplicate
        result[:duplicates] += 1
      else
        result[:errors] += 1
        result[:error_details] << {
          index: index,
          title: item[:title],
          url: item[:url],
          error: outcome[:error]
        }
      end
    end

    Rails.logger.info("[SoroRss] #{result.except(:error_details).to_json}")
    result
  rescue StandardError => e
    self.failure("Excepción importando RSS: #{e.class} - #{e.message}")
  end

  private

  def self.parse_items(xml)
    doc = Nokogiri::XML(xml)
    doc.xpath("//channel/item").map do |item_node|
      {
        title: text_for(item_node, "title"),
        description: text_for(item_node, "description"),
        content_html: text_for(item_node, "./*[local-name()='encoded']"),
        guid: text_for(item_node, "guid"),
        author: text_for(item_node, "author") || text_for(item_node, "./*[local-name()='creator']"),
        pub_date: parse_time(text_for(item_node, "pubDate")),
        image_url: image_url_for(item_node)
      }
    end
  end

  def self.import_item(item)
    time_current = Time.current
    title = item[:title].to_s.squish
    return { status: :error, error: "Título vacío" } if title.blank?
    return { status: :error, error: "Título muy corto (<15)" } if title.length < 15

    title = title.truncate(250, omission: "")
    content = item[:content_html].presence || item[:description].presence
    return { status: :error, error: "Contenido vacío" } if content.blank?

    extract = build_extract(item)
    return { status: :error, error: "Extract muy corto (<50)" } if extract.length < 50

    return { status: :duplicate } if duplicate?(title:, url: item[:url])

    post = Post.new(
      title: title,
      extract: extract,
      cate: :articulo,
      status: :publicado,
      publish_at: item[:pub_date] || time_current,
      created_at: item[:pub_date] || time_current,
      updated_at: item[:pub_date] || time_current,
      author: "Angel Padilla (Founder)",
      url_image: item[:image_url].presence
    )
    post.content = content

    if post.save
      { status: :created }
    else
      { status: :error, error: post.errors.full_messages.join(", ") }
    end
  end

  def self.duplicate?(title:, url:)
    scope = Post.where(title: title)
    scope = scope.or(Post.where(url: url)) if url.present?
    scope.exists?
  end

  def self.build_extract(item)
    candidate = item[:description].presence || item[:content_html].presence || ""
    text = ActionView::Base.full_sanitizer.sanitize(candidate.to_s).squish
    text.truncate(550, omission: "")
  end

  def self.image_url_for(item_node)
    media_content = item_node.at_xpath("./*[local-name()='content'][@url]")
    return media_content["url"] if media_content

    enclosure = item_node.at_xpath("./enclosure[@url]")
    enclosure&.[]("url")
  end

  def self.text_for(node, xpath)
    node.at_xpath(xpath)&.text&.strip
  end

  def self.parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError
    nil
  end

  def self.failure(message)
    Rails.logger.error("[SoroRss] #{message}")
    {
      success: false,
      feed_url: DEFAULT_FEED_URL,
      total_items: 0,
      created: 0,
      duplicates: 0,
      errors: 1,
      error_details: [ { error: message } ]
    }
  end
end
