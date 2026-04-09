class Event < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :corp
  belongs_to :user, optional: true

  enum :status, pendiente: 0, completado: 1, cancelado: 2

  scope :default, -> { order(hora_inicio: :desc) }
  scope :today, -> { where(hora_inicio: DateTime.now.beginning_of_day..DateTime.now.end_of_day) }

  validates :title, presence: { message: "El título es requerido" }
  # validates :body, presence: { message: "El cuerpo es requerido" }
  validates :hora_inicio, presence: { message: "La hora de inicio es requerida" }
  # validates :hora_final, presence: { message: "La hora final es requerida" }
  validates :customer_id, presence: { message: "El cliente es requerido" }
  # validates :user_id, presence: { message: "El usuario es requerido" }

  ## validar que un evento no se repita en el mismo rango de tiempo en la misma Corp
  validate :no_overlap_events, on: :create

  def no_overlap_events
    return if hora_inicio.blank? || hora_final.blank? || corp.blank?

    overlapping_events = Event.where(corp_id: corp_id)
                              .where.not(id: id)
                              .where("hora_inicio < ? AND hora_final > ?", hora_final, hora_inicio)

    if overlapping_events.exists?
      errors.add(:base, "Ya existe una cita en ese rango de tiempo")
    end
  end


  def start_time
    self.hora_inicio
  end

  def end_time
    self.hora_final
  end

  private

  def hora_final_after_hora_inicio
    return if hora_final.blank? || hora_inicio.blank?

    if hora_final < hora_inicio
      errors.add(:hora_final, "La hora final debe ser después de la hora de inicio")
    end
  end
end
