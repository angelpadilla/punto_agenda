class Deposit < ApplicationRecord
  belongs_to :depositable, polymorphic: true

  validates :monto, :forma_pago, :tipo, :depositable, presence: true

  scope :default, -> { order(created_at: :desc) }

  enum :tipo, ingreso: 0, egreso: 1
  enum :status_pago, pagado: 0, pendiente: 1, cancelado: 2, error_pago: 3, pagado_depositado: 4
  enum :canal, interno: 0, stripe: 1

  enum :forma_pago, {
    efectivo: "01",
    deposito_efectivo: "101",
    cheque_nominativo: "02",
    trasferencia_electronica: "03",
    tarjeta_de_credito: "04",
    monedero_electronico: "05",
    dinero_electronico: "06",
    vales_despensa: "08",
    tarjeta_de_debito: "28",
    tarjeta_de_servicio: "29",
    dacion_en_pago: "12",
    pago_por_subrogacion: "13",
    pago_por_consignacion: "14",
    condonacion: "15",
    compensacion: "17",
    novacion: "23",
    confusion: "24",
    remision_de_deuda: "25",
    caducidad: "26",
    a_satisfaccion_del_acreedor: "27",
    por_definir: "99"
  }

  def self.ransackable_attributes(auth_object = nil)
    %W[id monto num_operacion forma_pago tipo created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %W[depositable]
  end

  before_create :gen_folio

  private
  def gen_folio
    token = SecureRandom.alphanumeric(10).downcase
    while Order.where(folio: token).exists?
      token = SecureRandom.alphanumeric(10).downcase
    end
    self.folio = token
  end
end
