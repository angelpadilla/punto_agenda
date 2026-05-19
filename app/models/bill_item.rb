class BillItem < ApplicationRecord
  belongs_to :bill

  IVAS = [
    [ "IVA 16%", 16.0 ],
    [ "IVA 8%", 8.0 ],
    [ "IVA 0%", 0.0 ]
  ]

  ## validations
  validates :precio, presence: { message: "Precio es obligatorio" }, numericality: { greater_than: 0, message: "Precio debe ser mayor a 0" }
  validates :cantidad, presence: { message: "Cantidad es obligatoria" }, numericality: { greater_than: 0, message: "Cantidad debe ser mayor a 0" }
  validates :iva, inclusion: { in: IVAS.map(&:last), message: "no es un valor válido" }

  ## totales de linea
  def descuento_total
    self.descuento * self.cantidad
  end

  def total
   (self.precio * self.cantidad) - self.descuento_total
  end

  def subtotal
    self.total / (1 + (self.iva / 100))
  end

  def iva_total
    (self.total - self.subtotal)
  end

  def costo_total
    costo = self.costo || 0.0
    costo * self.cantidad
  end

  # def com_vendedor_total
  #   self.com_vendedor * self.cantidad
  # end

  def ganancia_total
    self.total - self.costo_total
  end

  ## individuales
  def subtotal_u
    self.precio / (1 + (self.iva / 100))
  end

  def iva_u
    self.precio - self.subtotal_u
  end

  def precio_descuento
    self.precio - self.descuento
  end
end
