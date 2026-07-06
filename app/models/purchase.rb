class Purchase < ApplicationRecord
  belongs_to :corp
  belongs_to :user, optional: true
  belongs_to :provider, optional: true

  has_many :deposits, as: :depositable, dependent: :destroy
  has_many :purchase_items, dependent: :destroy
  has_many :items, through: :purchase_items

  enum :forma_pago, {
    efectivo: 0,
    trasferencia_electronica: 1,
    tarjeta_de_credito: 2,
    tarjeta_de_debito: 3,
    cheque: 4,
    por_definir: 5
  }

  Status2 = [
    ["Remision", :remision],
    ["Pendiente", :pendiente]
  ]

  Status3 = [
    ["Remision", :remision],
    ["Pendiente", :pendiente],
    ["Cancelado", :cancelado],
  ]

  enum :status, carrito: 0, remision: 2, cancelado: 3
  enum :status_pago, pagado: 0, credito: 1
  enum :tipo, compra: 0, gasto: 1

  validates :forma_pago, presence: { message: ": Forma de pago es requerida" }, on: :update
  validates :deadline, presence: { message: ": Plazo del crédito es requerida" }, if: :credito?
  
  ## scopes
  scope :default, -> { order(created_at: :desc) }
  scope :default_index, -> { default.where.not(status: :carrito) }

  def add_item(item, quantity, price)
    line = self.purchase_items.where(item_id: item.id).first
    quantity = quantity.to_f
    # weight = weight.to_i.ceil

    if line
      line.cantidad += quantity
      line.save
    else
      self.purchase_items.create!(item_id: item.id, precio: price, cantidad: quantity)
    end
  end

  def down_item(line_id, quantity)
    line = self.purchase_items.where(id: line_id).first
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
    line = self.purchase_items.where(id: line_id).first
    line.destroy if line
  end

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id status status_pago deadline fecha created_at folio forma_pago provider_id tipo]
  end

  # Add this method to whitelist explicit associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[user provider]
  end


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
