class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :item, optional: true

  IVAS = [
    [ "IVA 16%", 16.0 ],
    [ "IVA 8%", 8.0 ],
    [ "IVA 0%", 0.0 ]
  ]

  ## validations
  validates :precio, presence: { message: "Precio es obligatorio" }, numericality: { greater_than: 0, message: "Precio debe ser igual o mayor a 0" }
  validates :cantidad, presence: { message: "Cantidad es obligatoria" }, numericality: { greater_than: 0, message: "Cantidad debe ser mayor a 0" }
  validates :iva, inclusion: { in: IVAS.map(&:last), message: "no es un valor válido" }

  scope :default, -> { order(created_at: :asc) }

  def total
    self.precio * self.cantidad
  end

  def subtotal
    self.total / (1 + (self.iva / 100))
  end

  def iva_total
    (self.total - self.subtotal)
  end

  def subtotal_u
    self.precio / (1 + (self.iva / 100))
  end

  def iva_u
    self.precio - self.subtotal_u
  end
end
