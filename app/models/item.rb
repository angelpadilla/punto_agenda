class Item < ApplicationRecord
  audited max_audits: 1000

  belongs_to :brand, optional: true
  belongs_to :sat_product, optional: true
  belongs_to :corp, optional: true

  has_one_attached :img1, dependent: :destroy
  has_one_attached :img2, dependent: :destroy
  has_one_attached :img3, dependent: :destroy
  has_one_attached :img4, dependent: :destroy
  has_one_attached :img5, dependent: :destroy

  enum :status, activo: 0, activo_interno: 1, inactivo: 2
  enum :cate, producto: 0, servicio: 1, consumible: 2

  Statuses = [
    [ "Activo (internamente y tienda online)", :activo ],
    [ "Activo interno (solo internamente)", :activo_interno ],
    [ "Inactivo", :inactivo ]
  ].freeze

  ## validaciones
  # validates :brand_id, presence: { message: "La marca es obligatoria" }
  validates :sat_product_id, presence: { message: "La clave de producto SAT es obligatoria" }
  validates :corp_id, presence: { message: "La empresa es obligatoria" }
  validates :name, presence: { message: "El nombre es obligatorio" }
  validates :unidad, presence: { message: "La unidad es obligatoria" }
  validates :cate, presence: { message: "La categoria es obligatoria" }
  validates :price, presence: { message: "El precio es obligatorio" }
  validates :price, numericality: { greater_than: 0, message: "El precio de contado debe ser mayor a 0" }
  validates :offer, numericality: { greater_than: 0, message: "El precio oferta debe ser mayor a 0" }, allow_blank: true
  validates :cost, numericality: { greater_than: 0, message: "El costo debe ser mayor a 0" }, allow_blank: true

  validates :offer,
          numericality: {
            greater_than: 0,
            less_than: :price,
            message: "El precio oferta debe ser mayor a 0 y menor al precio normal"
          },
          allow_blank: true,
          if: :price

  validates :img1, content_type: %w[image/png image/jpeg image/webp]
  validates :img1, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 1 debe ser menor a 5MB" }
  validates :img2, content_type: %w[image/png image/jpeg image/webp]
  validates :img2, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 2 debe ser menor a 5MB" }
  validates :img3, content_type: %w[image/png image/jpeg image/webp]
  validates :img3, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 3 debe ser menor a 5MB" }
  validates :img4, content_type: %w[image/png image/jpeg image/webp]
  validates :img4, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 4 debe ser menor a 5MB" }
  validates :img5, content_type: %w[image/png image/jpeg image/webp]
  validates :img5, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 5 debe ser menor a 5MB" }

  normalizes :name, with: ->(item) { item.strip.downcase.titleize }

  scope :default, -> { order("id asc") }
  scope :available, -> { where(status: [ :activo, :activo_interno ]).where("stock > 0 OR stock IS NULL") }

  ## broadcasting
  # after_create_commit { broadcast_prepend_to "items", partial: "user_panel/items/item", locals: { item: self }, target: "items" }
  # after_update_commit { broadcast_replace_to "items", partial: "user_panel/items/item", locals: { item: self }, target: "#{dom_id(self)}" }
  # after_destroy_commit { broadcast_remove_to "items", target: "#{dom_id(self)}" }

  UnidadSAT = [
    [ "Pieza", "H87" ],
    [ "Elemento", "EA" ],
    [ "Unidad de servicio", "E48" ],
    [ "Actividad", "ACT" ],
    [ "Kilogramo", "KGM" ],
    [ "Trabajo", "E51" ],
    [ "Tarifa", "A9" ],
    [ "Metro", "MTR" ],
    [ "Paquete a granel", "AB" ],
    [ "Caja base", "BB" ],
    [ "Kit", "KT" ],
    [ "Conjunto", "SET" ],
    [ "Litro", "LTR" ],
    [ "Caja", "XBX" ],
    [ "Mes", "MON" ],
    [ "Hora", "HUR" ],
    [ "Metro cuadrado", "MTK" ],
    [ "Equipos", "11" ],
    [ "Miligramo", "MGM" ],
    [ "Paquete", "XPK" ],
    [ "Kit (Conjunto de piezas)", "XKI" ],
    [ "Gramo", "GRM" ],
    [ "Par", "PR" ],
    [ "Docenas de piezas", "DPC" ],
    [ "Unidad", "xun" ],
    [ "Día", "DAY" ],
    [ "Lote", "XPK" ],
    [ "Mililitro", "MLT" ],
    [ "Viaje", "E54" ]
  ].freeze

  ImageFields1 = [
    [ "Imagen 1", :img1 ],
    [ "Imagen 2", :img2 ],
    [ "Imagen 3", :img3 ]
  ].freeze

  ImageFields2 = [
    [ "Imagen 1", :img1 ],
    [ "Imagen 2", :img2 ],
    [ "Imagen 3", :img3 ],
    [ "Imagen 4", :img4 ],
    [ "Imagen 5", :img5 ]
  ].freeze

  def self.ransackable_attributes(auth_object = nil)
    %W[id name cate price offer sku brand_name stock]
  end

  def self.ransackable_associations(auth_object = nil)
    %W[brand sat_product]
  end


  ## Class methods
  def self.similar(item)
    where.not(id: item.id).where("name LIKE ?", "%#{item.name}%")
  end

  # enum :tipo,  {
  #   carrito: "carrito",
  #   # credito: "credito",
  #   # pagado: "pagado",
  #   # cancelado: "cancelado",
  #   pre_factura: "pre_factura",
  #   cotizacion: "cotizacion",
  #   remision:
  #   factura:
  # }

  # enum :status_pago, {
  #   pagado: 0,
  #   credito: 1,
  #   cancelado: 2
  # }


  ## Instance methods
  def low_stock?
    if self.alerta_stock
      self.stock <= self.alerta_stock
    else
      self.stock <= 0
    end
  end

  # def self.low_stock
  #   self.all.sum { |item| item.low_stock? ? 1 : 0 }
  # end

  def last_order_at
    self.orders.order(created_at: :desc).last&.created_at
  end

  def last_event_at
    self.events.order(created_at: :desc).last&.created_at
  end
end
