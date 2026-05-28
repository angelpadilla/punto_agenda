class Event < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :corp
  belongs_to :user, optional: true

  enum :status, agendado: 0, completado: 1, cancelado: 2, por_confirmar: 3, ausencia: 4
  enum :canal, interno: 0, web: 1

  scope :default, -> { order(hora_inicio: :desc) }
  scope :upcoming, -> { where("hora_inicio >= ?", DateTime.now) }
  scope :past, -> { where("hora_inicio < ?", DateTime.now) }
  scope :indexx, -> { default.where.not(status: :cancelado) }
  scope :today, -> { where(hora_inicio: DateTime.now.beginning_of_day..DateTime.now.end_of_day) }

  validates :title, presence: { message: "El título es requerido" }
  # validates :body, presence: { message: "El cuerpo es requerido" }
  validates :hora_inicio, presence: { message: "La hora de inicio es requerida" }
  validates :hora_final, presence: { message: "La hora final es requerida" }
  validates :customer_id, presence: { message: "El cliente es requerido" }
  validates :user_id, presence: { message: "El agente/vendedor es requerido" }

  ## validar que un evento no se repita en el mismo rango de tiempo en la misma Corp, solo busca eventos pendientes o completados, no considera cancelados
  validate :no_overlap_events, on: :create


  def self.ransackable_attributes(auth_object = nil)
    %W[id title folio customer_id canal status user_id corp_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %W[customer user corp]
  end

  def no_overlap_events
    return if hora_inicio.blank? || hora_final.blank? || corp.blank?

    overlapping_events = Event.where(corp_id: corp_id, user_id: user_id, status: [:agendado, :completado])
                              .where.not(id: id)
                              .where("hora_inicio < ? AND hora_final > ?", hora_final, hora_inicio)

    if overlapping_events.exists?
      puts "Evento solapado encontrado: #{overlapping_events.pluck(:id).join(', ')}"
      errors.add(:base, "Ya existe un evento en ese rango de tiempo con ese agente vendedor")
    end
  end


  def start_time
    self.hora_inicio
  end

  def end_time
    self.hora_final
  end

  def self.due_today
    where(hora_inicio: DateTime.now.beginning_of_day..DateTime.now.end_of_day, status: :agendado)
  end

  before_create :set_folio
  after_create :add_customer_to_corp_portfolio

  private
  def set_folio
    token = SecureRandom.alphanumeric(7).upcase
    while Event.where(folio: token).exists?
      token = SecureRandom.alphanumeric(7).upcase
    end
    self.folio = token
  end

  def hora_final_after_hora_inicio
    return if hora_final.blank? || hora_inicio.blank?

    if hora_final < hora_inicio
      errors.add(:hora_final, "La hora final debe ser después de la hora de inicio")
    end
  end

  def add_customer_to_corp_portfolio
    return unless customer_id && corp_id
    CorpCustomer.find_or_create_by(corp_id: corp_id, customer_id: customer_id) do |cc|
      cc.source = "event"
    end
  end
end
