class Purchase < ApplicationRecord
  belongs_to :corp
  belongs_to :user, optional: true
  belongs_to :provider, optional: true

  has_many :deposits, as: :depositable, dependent: :destroy
  has_many :purchase_items, dependent: :destroy
  has_many :items, through: :purchase_items

  enum :forma_pago, {
    efectivo: "01",
    deposito_efectivo: "101",
    trasferencia_electronica: "03",
    tarjeta_de_credito: "04",
    tarjeta_de_debito: "28",
    cheque_nominativo: "02",
    monedero_electronico: "05",
    dinero_electronico: "06",
    vales_despensa: "08",
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
  enum :status, carrito: 0, remision: 1, cancelado: 3
  enum :status_pago, pendiente: 0, credito: 1, pagado: 2
  enum :tipo, compra: 0, gasto: 1

  validates :forma_pago, presence: { message: ": Forma de pago es requerida" }, on: :update
  validates :deadline, presence: { message: ": Plazo del crédito es requerida" }, if: :credito?
  
  ## scopes
  scope :default, -> { order(created_at: :desc) }
  scope :default_index, -> { default.where.not(status: :carrito) }



  before_save :set_1
  before_create :gen_folio

  private

  def set_1
    self.total = self.purchase_items.sum { |line| line.total }
    self.subtotal = self.purchase_items.sum { |line| line.subtotal }
    self.impuestos = self.purchase_items.sum { |line| line.iva_total }

    if self.pagado? or self.cancelado?
      self.debe = 0.0
      self.abonado = self.total
    elsif self.credito?
      self.debe = self.total - self.deposits.sum(:monto)
      self.abonado = self.deposits.sum(:monto)

      if self.abonado >= self.total and !self.carrito?
        self.status_pago = "pagado"
        self.debe = 0.0
      end
    end
  end

  def gen_folio
    token = SecureRandom.alphanumeric(9)
    while Purchase.where(folio: token).exists?
      token = SecureRandom.alphanumeric(9)
    end
    self.folio = token
  end
end
