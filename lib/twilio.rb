require "http"
module Twilio
  BaseUrl = "https://api.twilio.com/2010-04-01/Accounts/"
  EventsServiceID = "MG8351d82a20db3128f7beb3c3f4f72d2d"
  Account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
  Auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
  Base_url_sms = "#{BaseUrl}#{Account_sid}/Messages.json"


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
end
