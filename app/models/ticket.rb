class Ticket < ApplicationRecord
  belongs_to :corp, optional: true
  belongs_to :admin, optional: true
  has_many :ticket_messages, dependent: :destroy

  enum :status, abierto: 0, en_progreso: 1, resuelto: 2, cerrado: 3
  enum :priority, baja: 0, media: 1, alta: 2
  enum :category, soporte_tecnico: 0, facturacion: 1, consulta: 2, bug: 3, mejora: 4

  scope :default, -> { order(updated_at: :desc) }
  scope :activos, -> { where.not(status: :cerrado) }

  validates :title, presence: { message: "El título es requerido" }
  validates :description, presence: { message: "La descripción es requerida" }

  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  Status2 = [
    [ "En progreso", :en_progreso ],
    [ "Resuelto", :resuelto ],
    [ "Cerrado", :cerrado ]
  ]

  Status3 = [
    [ "Resuelto", :resuelto ],
    [ "Cerrado", :cerrado ]
  ]

  def self.ransackable_attributes(auth_object = nil)
    %w[id title description status priority category corp_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[corp admin]
  end

  def abierto_para_mensajes?
    !cerrado? && !resuelto?
  end

  def last_message_at
    ticket_messages.maximum(:created_at) || created_at
  end

  private

  def broadcast_status_change
    broadcast_replace_to(
      [ self, :info ],
      target: "ticket_info",
      partial: "shared/ticket_info",
      locals: { ticket: self }
    )

    broadcast_replace_to(
      [ self, :info ],
      target: "ticket_info_admin",
      partial: "admin/tickets/ticket_info",
      locals: { ticket: self }
    )

    unless abierto_para_mensajes?
      broadcast_replace_to(
        [ self, :reply ],
        target: "ticket_reply_area",
        partial: "shared/ticket_closed_notice",
        locals: { ticket: self }
      )
    end
  end
end
