class NewsApi
  BASE_URL = "https://newsapi.org/v2/everything"
  API_KEY = Rails.application.credentials.dig(:news_api)

  # Temas predefinidos para tu negocio
  QUERIES = {
    general: '(pymes OR emprendedores OR "pequeños negocios") AND (tecnologia OR digital OR software OR facturación)',
    facturacion: '("facturación electrónica" OR SAT OR CFDI OR impuestos) AND (México OR pymes)',
    pagos: "(pagos digitales OR fintech OR Stripe OR cobros) AND (negocios OR pymes)",
    ecommerce: '("comercio electrónico" OR ecommerce OR "tienda online") AND (pymes OR emprendedores)',
    marketing: "(marketing OR ventas) AND digital AND (pymes OR negocio)",
    economia: "(economía OR fiscal OR impuestos) AND México AND (empresas OR pymes)"
  }.freeze

  def self.fetch(topic: nil, quantity: 5, from: 7.days.ago, to: Time.current,
                 sort_by: "relevancy", language: "es")
    topic = QUERIES.keys.sample if topic.nil? || topic == :random
    query = QUERIES[topic] || QUERIES[:general]
    query_encoded = URI.encode_www_form_component(query)
    from_iso = from.iso8601
    to_iso = to.iso8601

    url = "#{BASE_URL}?q=#{query_encoded}&from=#{from_iso}&to=#{to_iso}" \
          "&pageSize=#{quantity}&sortBy=#{sort_by}&language=#{language}&apiKey=#{API_KEY}"

    res = HTTP.get(url)

    if res.status.success?
      articles = JSON.parse(res.to_s)["articles"]
      articles.each do |article|
        html_body = HTTP.get(article["url"]).to_s
        puts "HTTP request #{article['url']}"
        puts "-" * 50
        res2 = Deep.ask(question: "{'url': '#{article['url']}', 'html': '#{html_body}'}")
        # puts "Deep response: #{res2}"
        # puts "-" * 50
        if res2[:success]
          article["content"] = res2[:contenido]
        else
          article["content"] = nil
        end
      end

      {
        success: true,
        status: res.status.code,
        full_status: res.status.to_s,
        error: nil,
        error_code: nil,
        body: articles
      }
    else

      {
        success: false,
        status: res.status.code,
        full_status: res.status.to_s,
        error: JSON.parse(res.to_s)["message"] || "Error desconocido",
        error_code: JSON.parse(res.to_s)["code"] || "unknown_error",
        body: nil
      }
    end
  end
end
