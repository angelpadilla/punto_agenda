class Deep
  Api_url = "https://api.deepseek.com"

  def self.ask(question:, context: nil)
    api_key = Rails.application.credentials.dig(:deepseek, :api_key)

    response = HTTP.headers(content_type: "application/json", authorization: "Bearer #{api_key}")
                  .post("#{Api_url}/ask", json: {
                    model: "deepseek-v4-flash",
                    messages: [
                      {
                        role: "system",
                        content: "Eres un asistente útil y preciso para responder preguntas basadas en el contexto proporcionado. Si no sabes la respuesta, di que no lo sabes."
                      },
                      {
                        role: "user",
                        content: "Pregunta: #{question}\nContexto: #{context}"
                      }
                    ],
                    thinking: {
                      type: "enabled"
                    },
                    reasoning_effort: "high",
                    stream: false
                  })
    JSON.parse(response.body.to_s)
  end
end
