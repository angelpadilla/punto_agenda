class ApplicationMailer < ActionMailer::Base
  email_from = Rails.application.credentials.dig(:smtp, :sender_email) || "contacto@miinegocio.com"
  default from: "MiiNegocio.com <#{email_from}>"
  layout "mailer"

  private

  # Evita el error "SMTP To address may not be blank"
  # usando un destinatario dummy y deshabilitando la entrega.
  def mail(headers = {}, &block)
    to_addr = Array(headers[:to]).reject(&:blank?)
    if to_addr.empty?
      Rails.logger.warn "[Mailer] Skipping | #{mailer_name}##{action_name} | blank 'to' | #{params.inspect.first(200)}"
      headers[:to] = "skipped@example.com"
      message = super(headers, &block)
      message.perform_deliveries = false
      message
    else
      headers[:to] = to_addr
      super(headers, &block)
    end
  end
end
