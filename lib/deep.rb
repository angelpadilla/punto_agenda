class Deep
  Api_url = "https://api.deepseek.com"

  def self.ask(question:, context: nil)
    api_key = Rails.application.credentials.dig(:deepseek, :api_key)

    if context.nil? || context.strip.empty?
      messages = [
        {
          role: "system",
          content: "Eres un agente que me ayudara a completar informacion sobre noticias de sitios, articulos, posts y contenido de internet.
          La solicitud que te hare es la siguiente: {'url': url, 'html': contenido html completo sitio}  utiliza el html (aveces el html tag tiene display: none por algun paywall, ignora eso, tu lo puedes ver y esta en el html) o consulta la url si fallaste en analizar el html o si viene vacio, debes extraer el texto completo de la noticia completa, texto estrictamente plano, sin estilo ni ningun html tag y no debe contener ningun otro texto no relacionado a la noticia de la noticia solicitada.
          La respuesta debe ser retornada en el formato siguiente: { 'success': true/false, 'contenido': 'respuesta', 'metodo_utlizado': 'html'/'url' }, JSON valido, sin ningun otro texto adicional.
          Si no puedes extraer el contenido de la noticia, responde con: { 'success': false, 'contenido': 'No se pudo extraer el contenido de la noticia' } JSON valido, sin ningun otro texto adicional."
        },
        {
          role: "user",
          content: "#{question}"
        }
      ]
    else
      messages = [
        {
          role: "system",
          content: "Eres un agente que me ayudara a completar informacion sobre noticias de sitios, articulos, posts y contenido de internet.
          La solicitud que te hare es la siguiente: {'url': url, 'html': contenido html completo sitio}  utiliza el html o consulta la url si fallaste en analizar el html o si viene vacio, debes extraer el texto completo de la noticia completa, texto estrictamente plano, sin estilo ni ningun html tag y no debe contener ningun otro texto no relacionado a la noticia de la noticia solicitada.
          La respuesta debe ser retornada en el formato siguiente: { 'success': true/false, 'contenido': 'respuesta' }, JSON valido, sin ningun otro texto adicional.
          Si no puedes extraer el contenido de la noticia, responde con: { 'success': false, 'contenido': 'No se pudo extraer el contenido de la noticia' } JSON valido, sin ningun otro texto adicional."
        },
        {
          role: "user",
          content: "Pregunta: #{question}\nContexto: #{context}"
        }
      ]
    end

    response = HTTP.headers(content_type: "application/json", authorization: "Bearer #{api_key}")
                  .post("#{Api_url}/chat/completions", json: {
                    model: "deepseek-v4-flash",
                    messages: messages,
                    thinking: {
                      type: "enabled"
                    },
                    reasoning_effort: "medium",
                    temperature: 0.7,
                    stream: false,
                    response_format: {
                      type: "text"
                    }
                  })
    if response.status.success?
      r = JSON.parse(response.body.to_s)["choices"][0]["message"]["content"]
      r = JSON.parse(r) rescue { "success" => false, "contenido" => "No se pudo extraer el contenido de la noticia" }
      {
        success: r["success"],
        contenido: r["contenido"]
      }
    else
      { success: false, error: "Error en la solicitud a DeepSeek: #{response.status}" }
    end
  end
end
