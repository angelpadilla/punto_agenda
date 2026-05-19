class Bill < ApplicationRecord
  belongs_to :corp
  has_many :bill_items, dependent: :destroy

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id tipo corp_id folio forma_pago status_pago]
  end

  # Add this method to whitelist explicit associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[corp bill_items]
  end

  enum :tipo,  {
    remision: "remision",
    factura: "factura"
  }

  enum :status_pago, {
    pagado: "pagado",
    cancelado: "cancelado",
    error_pago: "error_pago",
    pendiente: "pendiente"
  }

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

  UsoCFDI = [
    [ "Gastos en general", "G03" ],
    [ "Adquisicion de mercancias", "G01" ],
    [ "Sin efectos fiscales (publico en general)", "S01" ],
    [ "Devoluciones, descuentos o bonificaciones", "G02" ],
    [ "Construcciones", "I01" ],
    [ "Mobilario y equipo de oficina por inversiones", "I02" ],
    [ "Equipo de transporte", "I03" ],
    [ "Equipo de computo y accesorios", "I04" ],
    [ "Dados, troqueles, moldes, matrices y herramentas", "I05" ],
    [ "Comunicaciones telefónicas", "I06" ],
    [ "Comunicaciones satelitales", "I07" ],
    [ "Otra maquinaria y equipo", "I08" ],
    [ "Honorarios médicos, dentales y gastos hospitalarios", "D01" ],
    [ "Gastos médicos por incapacidad o discapacidad", "D02" ],
    [ "Gastos funerales", "D03" ],
    [ "Donativos", "D04" ],
    [ "Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación)", "D05" ],
    [ "Aportaciones voluntarias al SAR", "D06" ],
    [ "Primas por seguros de gastos médicos", "D07" ],
    [ "Gastos de transportación escolar obligatori", "D08" ],
    [ "Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones", "D09" ],
    [ "Pagos por servicios educativos (colegiaturas)", "D10" ]
  ]

  scope :default, -> { order(created_at: :desc) }
  scope :pagados, -> { default.pagado }
  scope :remisiones, -> { default.remision }
  scope :facturas, -> { default.factura }

  ## Validations
  validates :tipo, :forma_pago, presence: { message: "El tipo de orden es requerido" }
  validates :total, numericality: { greater_than_or_equal_to: 0, message: "El total debe ser un número positivo" }, allow_nil: true
  validates :subtotal, numericality: { greater_than_or_equal_to: 0, message: "El subtotal debe ser un número positivo" }, allow_nil: true
  validates :impuestos, numericality: { greater_than_or_equal_to: 0, message: "Los impuestos deben ser un número positivo" }, allow_nil: true
  validates :descuento, numericality: { greater_than_or_equal_to: 0, message: "El descuento debe ser un número positivo" }, allow_nil: true
  validates :costo, numericality: { greater_than_or_equal_to: 0, message: "El costo debe ser un número positivo" }, allow_nil: true
  validates :ganancia, numericality: { greater_than_or_equal_to: 0, message: "La ganancia debe ser un número positivo" }, allow_nil: true


  before_save :calcular_totales
  before_create :gen_folio

  def timbre?
    if self.xml.present? and self.sat_uuid.present?
      true
    else
      false
    end
  end

  def calcular_totales
    ## TODO 
    self.total = self.bill_items.sum {|item| item.total }
    self.subtotal = self.bill_items.sum {|item| item.subtotal }
    self.impuestos = self.bill_items.sum {|item| item.iva_total }
    self.descuento = self.bill_items.sum {|item| item.descuento_total }
    self.costo = self.bill_items.sum {|item| item.costo_total }
    self.ganancia = self.total - self.costo
  end

  def gen_folio
    timestamp = DateTime.now.strftime("%Y%m%d%H%M%S")
    # random_string = SecureRandom.alphanumeric(3)
    self.folio = "#{self.corp_id}-#{self.id}-#{timestamp}"
  end

end
