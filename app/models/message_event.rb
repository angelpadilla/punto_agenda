class MessageEvent < ApplicationRecord
  belongs_to :corp
  belongs_to :eventeable, polymorphic: true
  belongs_to :customer

  enum :status, pendiente: 0, enviado: 1, fallido: 2
  enum :tipo, sms: 0, email: 1, whatsapp: 2

  validates :tipo, :to, presence: true
  validates :prefix, :body, presence: true, if: :sms?
  # validates :body, presence: true, if: :email?

  def self.ransackable_attributes(auth_object = nil)
    %W[id to prefix body status tipo eventeable_type eventeable_id customer_id corp_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %W[customer corp eventeable]
  end

  after_create :send_message

  private

  def send_message
    case tipo
    when "sms"
      send_sms
    when "email"
      send_email
    when "whatsapp"
      send_whatsapp
    end
  end

  def send_sms
    response = SmsService.sms(to: to, code: prefix, body: body)

    if response[:success]
      update(status: :enviado, response: response[:message])
      self.corp.decrement!(:sms)
    else
      update(status: :fallido, response: response[:message])
    end
  end

  def send_email
    if eventeable.is_a?(Event)
      EventMailer.with(event: eventeable, email: to).send_event.deliver_later
      update(status: :enviado, response: "Email programado para envío")
    elsif eventeable.is_a?(Order)
      OrderMailer.with(order: eventeable, email: to).send_order.deliver_later
      update(status: :enviado, response: "Email programado para envío")
    else
      update(status: :fallido, response: "Tipo de evento no soportado para email")
    end
  end

  def send_whatsapp
    # Implementar lógica para enviar mensaje de WhatsApp usando un API externo
  end
end
