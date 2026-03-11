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

  enum :status, { activo: 0, inactivo: 1 }
  enum :cate, producto: 0, servicio: 1, consumible: 2

  ## validaciones
  validates :brand_id, presence: { message: "La marca es obligatoria" }
  validates :sat_product_id, presence: { message: "La clave de producto SAT es obligatorio" }
  validates :corp_id, presence: { message: "La empresa es obligatoria" }
  validates :name, presence: { message: "El nombre es obligatorio" }
  validates :price, presence: { message: "El precio es obligatorio" }
  validates :unidad, presence: { message: "La unidad es obligatoria" }
  validates :cate, presence: { message: "La categoria es obligatoria" }

  validates :img1, content_type: %w[image/png image/jpeg]
  validates :img1, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 1 debe ser menor a 5MB" }
  validates :img2, content_type: %w[image/png image/jpeg]
  validates :img2, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 2 debe ser menor a 5MB" }
  validates :img3, content_type: %w[image/png image/jpeg]
  validates :img3, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 3 debe ser menor a 5MB" }
  validates :img4, content_type: %w[image/png image/jpeg]
  validates :img4, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 4 debe ser menor a 5MB" }
  validates :img5, content_type: %w[image/png image/jpeg]
  validates :img5, size: { less_than_or_equal_to: 5.megabytes, message: "La imagen 5 debe ser menor a 5MB" }

  scope :default, -> { order("id asc") }

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
    [ "Variedad", "AS" ],
    [ "Gramo", "GRM" ],
    [ "Par", "PR" ],
    [ "Docenas de piezas", "DPC" ],
    [ "Unidad", "xun" ],
    [ "Día", "DAY" ],
    [ "Lote", "XPK" ],
    [ "Grupos", "10" ],
    [ "Mililitro", "MLT" ],
    [ "Viaje", "E54" ]
  ]

  def self.ransackable_attributes(auth_object = nil)
    %W[id name cate price offer sku brand_name stock]
  end

  def self.ransackable_associations(auth_object = nil)
    %W[brand sat_product]
  end
end
