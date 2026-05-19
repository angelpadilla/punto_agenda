class Corp < ApplicationRecord
  audited max_audits: 100

  has_many :users, dependent: :nullify
  has_many :items, dependent: :destroy
  has_many :events, dependent: :nullify
  has_many :providers, dependent: :nullify
  has_many :brands, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :deposits, through: :orders
  has_many :sat_products, dependent: :destroy

  has_many :corp_customers, dependent: :destroy
  has_many :customers, through: :corp_customers

  has_one_attached :key, dependent: :destroy
  has_one_attached :cer, dependent: :destroy
  has_one_attached :logo, dependent: :destroy

  serialize :business_hours, coder: JSON

  DAYS_OF_WEEK = {
    "0" => "Domingo",
    "1" => "Lunes",
    "2" => "Martes",
    "3" => "Miércoles",
    "4" => "Jueves",
    "5" => "Viernes",
    "6" => "Sábado"
  }.freeze

  DEFAULT_BUSINESS_HOURS = {
    "0" => { "active" => false, "open" => "09:00", "close" => "18:00" },
    "1" => { "active" => true,  "open" => "09:00", "close" => "18:00" },
    "2" => { "active" => true,  "open" => "09:00", "close" => "18:00" },
    "3" => { "active" => true,  "open" => "09:00", "close" => "18:00" },
    "4" => { "active" => true,  "open" => "09:00", "close" => "18:00" },
    "5" => { "active" => true,  "open" => "09:00", "close" => "18:00" },
    "6" => { "active" => false, "open" => "09:00", "close" => "18:00" }
  }.freeze

  SLOT_DURATION_OPTIONS = [
    [ "15 min", 15 ], [ "30 min", 30 ], [ "45 min", 45 ],
    [ "1 hora", 60 ], [ "1 hora 15 min", 75 ], [ "1 hora 30 min", 90 ], [ "1 hora 45 min", 105 ],
    [ "2 horas", 120 ], [ "2 horas 15 min", 135 ], [ "2 horas 30 min", 150 ], [ "2 horas 45 min", 165 ],
    [ "3 horas", 180 ], [ "3 horas 15 min", 195 ], [ "3 horas 30 min", 210 ], [ "3 horas 45 min", 225 ],
    [ "4 horas", 240 ], [ "4 horas 15 min", 255 ], [ "4 horas 30 min", 270 ], [ "4 horas 45 min", 285 ],
    [ "5 horas", 300 ]
  ].freeze

  enum :tipo_plan, basico: 0, plus: 1, premium: 2
  enum :status, inactivo: "inactivo", activo: "activo", probando: "probando", suspendido: "suspendido", moroso: "moroso"


  TipoNegocios = [
    [ "💈 Barberia", "barberia" ],
    [ "💇‍♀️ Salon de belleza", "salon_belleza" ],
    [ "☕ Cafetería", "cafeteria" ],
    [ "🛒 Tienda", "tienda" ],
    [ "🛠️ Servicios", "servicios" ],
    [ "❓ Otro", "otro" ]
  ].freeze

  validates :tipo_negocio, presence: { message: "El tipo de negocio es requerido" }, inclusion: { in: TipoNegocios.map(&:last), message: "Tipo de negocio no válido" }

  validates :name, :phone, :tel_prefix, presence: true, on: :update
  validates :email, presence: true, on: :update

  validates :tel_prefix, inclusion: { in: Customer::TelPrefixes.keys, message: "Prefijo no válido" }
  validates :phone, format: { with: /\A\+?\d+\z/, message: "Teléfono debe ser un número valido" }
  validates :phone, length: { maximum: 10, message: "Teléfono debe tener máximo 10 dígitos" }

  # validates :whatsapp, format: { with: /\A\+?\d+\z/, message: "Teléfono debe ser un número valido" }, allow_blank: true
  # validates :whatsapp, length: { maximum: 15, message: "Teléfono debe tener máximo 15 dígitos" }, allow_blank: true

  # validates :razon, :rfc, :regimen, :estado, :cp, :ciudad, :colonia, :calle, :num_ext, presence: true, if: :facturacion?, on: :update
  ## custom validator
  validate :facturacion_datos
  validate :key_pass_if_key_cer
  validates :cp, numericality: true, length: { is: 5 }, on: :update, if: :facturacion?
  validates :rfc, length: { in: 10..13 }, on: :update, if: :facturacion?

  validates :key, content_type: ".key", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :cer, content_type: ".cer", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :logo, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update

  normalizes :name, :razon, :cp, :ciudad, :colonia, :localidad, :calle, :num_ext, :num_int, :phone, with: ->(e) { e.strip.downcase }
  normalizes :rfc, with: ->(e) { e.strip.upcase }

  def self.ransackable_attributes(auth_object = nil)
    %W[id name razon rfc regimen]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  def full_name
    "#{razon} #{rfc}"
  end

  def full_tel
    "#{tel_prefix} #{phone}"
  end

  def facturacion?
    if self.facturacion and self.cp.present? and self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present? and self.key_pass.present? and self.key.attached? and self.cer.attached?
      true
    else
      false
    end
  end

  def fac_and_timbres?
    if self.facturacion and self.cp.present? and self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present? and self.key_pass.present? and self.key.attached? and self.cer.attached? and self.timbres > 0
      true
    else
      false
    end
  end

  def facturacion_datos
    if facturacion
      errors.add(:razon, "La razón social es requerida") if razon.blank?
      errors.add(:rfc, "El RFC es requerido") if rfc.blank?
      errors.add(:regimen, "El régimen fiscal es requerido") if regimen.blank?
      errors.add(:estado, "El estado es requerido") if estado.blank?
      errors.add(:cp, "El código postal es requerido") if cp.blank?
      errors.add(:ciudad, "La ciudad es requerida") if ciudad.blank?
      errors.add(:colonia, "La colonia es requerida") if colonia.blank?
      errors.add(:calle, "La calle es requerida") if calle.blank?
      errors.add(:num_ext, "El número exterior es requerido") if num_ext.blank?
    end
  end

  def key_pass_if_key_cer
    if key.attached? && cer.attached? && key_pass.blank?
      errors.add(:key_pass, "La contraseña del certificado es requerida si se han subido el .key y el .cer")
    end
  end


  States = [
    [ "Aguascalientes", "aguascalientes" ],
    [ "Baja California", "baja_california" ],
    [ "Baja California Sur", "baja_california_sur" ],
    [ "Campeche", "campeche" ],
    [ "Coahuila de Zaragoza", "coahuila" ],
    [ "Colima", "colima" ],
    [ "Chiapas", "chiapas" ],
    [ "Chihuahua", "chihuahua" ],
    [ "Distrito Federal", "df" ],
    [ "Durango", "durango" ],
    [ "Guanajuato", "guanajuato" ],
    [ "Guerrero", "guerrero" ],
    [ "Hidalgo", "hidalgo" ],
    [ "Jalisco", "jalisco" ],
    [ "México", "mexico" ],
    [ "Michoacán de Ocampo", "michoacan" ],
    [ "Morelos", "morelos" ],
    [ "Nayarit", "nayarit" ],
    [ "Nuevo León", "nuevo_leon" ],
    [ "Oaxaca", "oaxaca" ],
    [ "Puebla", "puebla" ],
    [ "Querétaro", "queretaro" ],
    [ "Quintana Roo", "quintana_roo" ],
    [ "San Luis Potosí", "san_luis" ],
    [ "Sinaloa", "sinaloa" ],
    [ "Sonora", "sonora" ],
    [ "Tabasco", "tabasco" ],
    [ "Tamaulipas", "tamaulipas" ],
    [ "Tlaxcala", "tlaxcala" ],
    [ "Veracruz", "varacruz" ],
    [ "Yucatán", "yucatan" ],
    [ "Zacatecas", "zacatecas" ]
  ]

  RegimenFiscales = [
    [ "Sin obligaciones fiscales (público en general)", "616" ],
    [ "General de Ley personas Morales", "601" ],
    [ "Personas Físicas con Actividades Empresariales y Profesionales", "612" ],
    [ "Personas Morales con Fines no Lucrativos", "603" ],
    [ "Sueldos y Salarios e Ingresos Asimilados a Salarios", "605" ],
    [ "Arrendamiento", "606" ],
    [ "Demás ingresos", "608" ],
    [ "Consolidación", "609" ],
    [ "Residentes en el Extranjero sin Establecimiento Permanente en México", "610" ],
    [ "Ingresos por Dividendos (socios y accionistas)", "611" ],
    [ "Ingresos por intereses", "614" ],
    [ "Sociedades Cooperativas de Producción que optan por diferir sus ingresos", "620" ],
    [ "Incorporación Fiscal", "621" ],
    [ "Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras", "622" ],
    [ "Opcional para Grupos de Sociedades", "623" ],
    [ "Coordinados", "624" ],
    [ "Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas", "625" ],
    [ "Régimen Simplificado de Confianza", "626" ],
    [ "Régimen de Enajenación o Adquisición de Bienes", "607" ],
    [ "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales", "629" ],
    [ "Enajenación de acciones en bolsa de valores", "630" ],
    [ "Régimen de los ingresos por obtención de premios", "615" ]
  ]

  after_initialize :set_default_business_hours
  before_save :normalize_business_hours

  before_create :set_defaults
  after_create :create_stripe_customer

  def working_day?(date)
    return false if business_hours.blank?

    day_config = business_hours[date.wday.to_s]
    return false if day_config.nil?

    day_config["active"] == true
  end

  def slot_duration_label
    SLOT_DURATION_OPTIONS.find { |_, v| v == (slot_duration || 15) }&.first || "#{slot_duration || 15} min"
  end

  def to_fullcalendar_business_hours
    return [] if business_hours.blank?

    business_hours.filter_map do |wday, config|
      next unless config["active"] == true

      {
        daysOfWeek: [ wday.to_i ],
        startTime: config["open"],
        endTime: config["close"]
      }
    end
  end

  def prop
    users.find_by(tipo: "propietario")
  end

  def create_stripe_customer
    return if stripe_customer_id.present?
    customer = StripeClient.v1.customers.create({name: self.name, email: self.prop.email})
    if customer && customer.id
      update(stripe_customer_id: customer.id)
    else
      puts "-- Error creating Stripe customer for Corp #{id}: #{customer.inspect}"
    end
  end

  private

  def set_default_business_hours
    self.business_hours ||= DEFAULT_BUSINESS_HOURS.deep_dup
  end

  def normalize_business_hours
    return if business_hours.blank?

    business_hours.each do |_wday, config|
      config["active"] = ActiveModel::Type::Boolean.new.cast(config["active"])
    end
  end

  def set_defaults
    self.sku = generate_unique_sku
  end

  def generate_unique_sku
    token = SecureRandom.alphanumeric(8)
    return token unless self.class.exists?(sku: token)

    generate_unique_sku
  end
end
