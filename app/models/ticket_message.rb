class TicketMessage < ApplicationRecord
  belongs_to :ticket, touch: true
  belongs_to :sender, polymorphic: true

  validates :body, presence: { message: "El mensaje no puede estar vacío" }

  after_create_commit :broadcast_message
  after_create_commit :broadcast_ticket_info

  private

  def broadcast_message
    broadcast_append_to(
      [ ticket, :messages ],
      target: "ticket_messages",
      partial: "shared/message",
      locals: { message: self }
    )
  end

  def broadcast_ticket_info
    broadcast_replace_to(
      [ ticket, :info ],
      target: "ticket_info",
      partial: "shared/ticket_info",
      locals: { ticket: ticket }
    )
  end
end
