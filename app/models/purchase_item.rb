class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :item, optional: true

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
