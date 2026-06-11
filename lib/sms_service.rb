class SmsService
  BaseUrl = "https://api.twilio.com/2010-04-01/Accounts/"
  EventsServiceID = "MG8351d82a20db3128f7beb3c3f4f72d2d"
  Account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
  Auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
  Base_url_sms = "#{BaseUrl}#{Account_sid}/Messages.json"

  Masive_key = "e8a74df9175969981ecf9beb1700be"
  Masive_url_sms = "https://api.smsmasivos.com.mx/sms/send"


  def self.send_sms(to:, body:)
    response = HTTP.basic_auth(user: Account_sid, pass: Auth_token).post(Base_url_sms, form: {
      To: to,
      MessagingServiceSid: EventsServiceID,
      Body: body }
    )

    {
      success: response.status.success?,
      status: response.status.code,
      full_status: response.status.to_s,
      error: response.status.success? ? nil : JSON.parse(response.body.to_s)["error_message"],
      error_code: response.status.success? ? nil : JSON.parse(response.body.to_s)["error_code"],
      body: JSON.parse(response.body.to_s)
    }
  end

  # Envía un SMS usando la API de Altiria.
  #
  # @param :to [Array<String>] Número de teléfono destino, con prefijo internacional, sin el signo. (obligatorio, ej: "521234567890")
  # @param :from [String] Sender text, this label will consist of 15 numbers or 11 alphanumeric characters. (opcional, por defecto "POSAgenda")
  # @param :body [String] Contenido del mensaje (obligatorio)
  # @param :scheduleDate [String] Fecha y hora de envío programado en formato YYYYmmddHHiiss (opcional)
  # @param :notificationUrl [String] URL para recibir notificaciones de entrega (opcional)
  # @param :campaignName [String] Nombre de la campaña para reportes en panel de Altiria (opcional)
  # @param :flash [Boolean] Si true, el mensaje se mostrará como mensaje flash en el dispositivo del destinatario (opcional)
  # @return [Hash] Resultado de la petición con las siguientes claves:
  #   - :success [Boolean] true si el envío fue exitoso
  #   - :status [Integer] código HTTP de respuesta
  #   - :error [String, nil] mensaje de error o nil si fue exitoso
  #   - :body [Hash] respuesta completa de la API
  #   - :campaignId [String, nil] ID de campaña asignada por Altiria si fue exitoso
  #   - :sendingId [String, nil] ID de envío asignada por Altiria si fue exitoso
  def self.send_sms_b(to:, from: "POSAgenda", body:, scheduleDate: nil, notificationUrl: nil, campaignName: nil, flash: false)
    username = Rails.application.credentials.dig(:altiria, :username)
    api_password = Rails.application.credentials.dig(:altiria, :api_password)
    url_sms_altiria = "https://api.altiria.com/api/rest/sms"
    token = Base64.strict_encode64("#{username}:#{api_password}")

    ## aseguramos :from no tenga espacios y no exceda 11 caracteres
    from = from.gsub(/\s+/, "").slice(0, 11)

    response = HTTP.headers(content_type: "application/json", authorization: "Basic #{token}").post(url_sms_altiria, json: {
      to: to,
      from: from,
      message: body,
      scheduleDate: scheduleDate,
      notificationUrl: notificationUrl,
      campaignName: campaignName,
      flash: flash
    })

    {
      success: response.status.success?,
      status: response.status.code,
      full_status: response.status.to_s,
      error: response.status.success? ? nil : JSON.parse(response.to_s)["error"]["description"],
      error_code: response.status.success? ? nil : JSON.parse(response.to_s)["error"]["code"],
      campaignId: response.status.success? ? JSON.parse(response.to_s)["campaignId"] : nil,
      sendingId: response.status.success? ? JSON.parse(response.to_s)["sendingId"] : nil,
      body: JSON.parse(response.to_s)["result"]
    }
  end


  # Método alternativo para enviar SMS usando la API de MasiveSMS.
  # @param :to [String] numero de tel o numeros separados por coma, sin prefijo internacional ni signos, ej: "3312345678" o "3312345678,3398765432" (obligatorio)
  # @param :body [String] Contenido del mensaje (obligatorio)
  # @param :country_code [String] Código de país para el número de destino, sin el signo. (opcional, por defecto "52" para México)
  # @return [Hash] Resultado de la petición con las siguientes claves:
  #   - :success [Boolean] true si el envío fue exitoso
  #   - :status [Integer] código HTTP de respuesta
  #   - :error [String, nil] mensaje de error o nil si fue exitoso
  #   - :body [Hash] respuesta completa de la API
  def self.sms(to:, body:, code: "52")
    code =  code.to_s.gsub(/\D/, "") # Asegura que el código solo contenga dígitos
    puts "⚠️⚠️⚠️ Enviando SMS con MasiveSMS a #{to} con código de país #{code}"
    p to
    p code

    ## truncar body a 160 caracteres para evitar errores de API
    body = body.to_s.slice(0, 160)

    response = HTTP.headers(content_type: "application/json", apikey: Masive_key).post(Masive_url_sms, form: {
      message: body,
      numbers: to,
      country_code: code
    })

    puts "Respuesta de MasiveSMS: #{response.to_s}"

    response_body = JSON.parse(response.to_s)

    {
      success: response_body["success"],
      status: response_body["status"],
      message: response_body["message"],
      total_messages: response_body["total_messages"],
      references: response_body["references"],
      credit: response_body["credit"],
      id: response_body["request_id"],
      body: response_body
    }
  end
end
