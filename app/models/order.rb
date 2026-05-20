class Order < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :customer, optional: true
  belongs_to :corp
  belongs_to :seller, class_name: "User", foreign_key: :seller_id, optional: true

  has_many :deposits, as: :depositable, dependent: :destroy
  has_many :line_items, dependent: :destroy
  has_many :items, through: :line_items

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id tipo customer_id folio status_pago]
  end

  # Add this method to whitelist explicit associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[customer seller]
  end

  enum :tipo,  {
    carrito: "carrito",
    pre_factura: "pre_factura",
    cotizacion: "cotizacion",
    remision: "remision",
    factura: "factura"
  }

  Tipo2 = [
    [ "Remisión", :remision ],
    [ "Factura", :factura ],
    [ "Cotización", :cotizacion ],
    [ "Pre-factura", :pre_factura ]
  ]

  Tipo3 = [
    [ "Remisión", :remision ],
    [ "Cotización", :cotizacion ],
    [ "Pre-factura", :pre_factura ]
  ]

  enum :status_pago, {
    pagado: "pagado",
    credito: "credito",
    cancelado: "cancelado",
  }

  Status = [
    [ "Pagado", :pagado ],
    [ "Crédito", :credito ]
  ]

  Status_new_sale = [
    [ "Pagado", :pagado ],
    [ "Crédito", :credito ]
  ]

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

  ## scopes ...
  scope :default, -> { order(created_at: :desc) }
  scope :carritos, -> { where(tipo: "carrito") }
  scope :not_carritos, -> { default.where.not(tipo: "carrito") }
  scope :pre_facturas, -> { where(tipo: "pre_factura") }
  scope :cotizaciones, -> { where(tipo: "cotizacion") }
  scope :remisiones, -> { where(tipo: "remision") }
  scope :facturas, -> { where(tipo: "factura") }

  scope :pagados, -> { where(status_pago: "pagado") }
  scope :creditos, -> { where(status_pago: "credito") }
  scope :cancelados, -> { where(status_pago: "cancelado") }

  ## Validations
  validates :tipo, presence: { message: "El tipo de orden es requerido" }
  validates :status_pago, presence: { message: "El status de pago es requerido" }, if: :not_pre_factura_carrito?
  validates :total, numericality: { greater_than_or_equal_to: 0, message: "El total debe ser un número positivo" }, allow_nil: true
  validates :subtotal, numericality: { greater_than_or_equal_to: 0, message: "El subtotal debe ser un número positivo" }, allow_nil: true
  validates :impuestos, numericality: { greater_than_or_equal_to: 0, message: "Los impuestos deben ser un número positivo" }, allow_nil: true
  validates :descuento, numericality: { greater_than_or_equal_to: 0, message: "El descuento debe ser un número positivo" }, allow_nil: true
  validates :costo, numericality: { greater_than_or_equal_to: 0, message: "El costo debe ser un número positivo" }, allow_nil: true
  # validates :ganancia, numericality: { greater_than_or_equal_to: 0, message: "La ganancia debe ser un número positivo" }, allow_nil: true
  validates :debe, numericality: { greater_than_or_equal_to: 0, message: "El debe debe ser un número positivo" }, allow_nil: true
  validates :abonado, numericality: { greater_than_or_equal_to: 0, message: "El abonado debe ser un número positivo" }, allow_nil: true

  validates :forma_pago, presence: { message: ": Forma de pago es requerida" }, on: :update
  validates :deadline, presence: { message: ": Plazo del crédito es requerida" }, if: :credito?
  validates :fecha, presence: { message: ": Fecha de venta es requerida" }, on: :update

  validates :customer_id, presence: { message: ": Cliente es requerido" }, on: :update, if: :not_pre_factura_carrito?


  def not_pre_factura_carrito?
    self.tipo != "pre_factura" && self.tipo != "carrito"
  end

  def remision_factura?
    self.tipo == "remision" || self.tipo == "factura"
  end

  def timbre?
    if self.xml.present? and self.sat_uuid.present?
      true
    else
      false
    end
  end

  def add_item(item, quantity, price, discount = 0.0)
    line = self.line_items.where(item_id: item.id).first
    quantity = quantity.to_f
    costo = item.cost || 0.0
    # weight = weight.to_i.ceil

    if line
      line.cantidad += quantity
      line.save
    else
      self.line_items.create(item_id: item.id, precio: price, costo: costo, descuento: discount, cantidad: quantity)
    end
  end

  def down_item(line_id, quantity)
    line = self.line_items.where(id: line_id).first
    quantity = quantity.to_f

    if line.nil?
      return
    end

    if line.cantidad <= quantity
      line.destroy
    else
      line.cantidad -= quantity
      line.save
    end
  end

  def destroy_item(line_id)
    line = self.line_items.where(id: line_id).first
    line.destroy if line
  end

  before_save :set_1
  before_create :gen_folio
  after_create :add_customer_to_corp_portfolio

  private

  def set_1
    puts "- - - - - -Calculando totales para la orden #{self.id}"
    self.total = self.line_items.sum { |line| line.total }
    self.subtotal = self.line_items.sum { |line| line.subtotal }
    self.impuestos = self.line_items.sum { |line| line.iva_total }
    self.descuento = self.line_items.sum { |line| line.descuento_total }
    self.costo = self.line_items.sum { |line| line.costo_total }
    # self.ganancia = self.line_items.sum { |line| line.ganancia_total }
    self.costo_terminal = self.deposits.sum(:comision_terminal)
    self.ganancia = self.total - self.costo - self.costo_terminal

    puts "Total: #{self.total}, Subtotal: #{self.subtotal}, Impuestos: #{self.impuestos}, Descuento: #{self.descuento}, Costo: #{self.costo}, Ganancia: #{self.ganancia}"


    ## asignar sku si no lo tiene, y si es remision, factura o pre_factura
    # if !self.sku.present? and [ "remision", "factura", "pre_factura" ].include?(self.tipo)
    #   self.sku = @setting.contador_ventas
    #   @setting.increment!(:contador_ventas)
    # end

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

  def add_customer_to_corp_portfolio
    return unless customer_id && corp_id
    CorpCustomer.find_or_create_by(corp_id: corp_id, customer_id: customer_id) do |cc|
      cc.source = "compra"
    end
  end

  def gen_folio
    token = SecureRandom.alphanumeric(9)
    while Order.where(folio: token).exists?
      token = SecureRandom.alphanumeric(9)
    end
    self.folio = token
  end
end
