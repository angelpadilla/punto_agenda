class Setting < ApplicationRecord
  has_rich_text :legal_privacidad
  has_rich_text :legal_terminos
  has_one_attached :logo, dependent: :destroy
  has_one_attached :key, dependent: :destroy
  has_one_attached :cer, dependent: :destroy

  validates :key, content_type: ".key", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :cer, content_type: ".cer", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :logo, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update

  validates :razon, :rfc, :regimen, :estado, :cp, :ciudad, :colonia, :calle, :num_ext, :phone, :name, presence: true
  validates :cp, numericality: true, length: { maximum: 5 }
  validates :rfc, length: { in: 10..13 }
  validates :phone, numericality: true, length: { maximum: 10 }
  validates :tel_prefix, presence: true, inclusion: { in: Customer::TelPrefixes.keys, message: "Prefijo no válido" }

  validate :key_pass_if_key_cer

  normalizes :name, :cp, with: ->(e) { e.strip }
  normalizes :ciudad, :localidad, :colonia, :calle, :num_int, :num_ext, :domain, :instagram_url, :tiktok_url, :facebook_url, :phone, :email, with: ->(e) { e.strip.downcase }

  normalizes :rfc, with: ->(e) { e.strip.upcase }

  PlanPrices = {
    basico: {
      name: "Plan Básico",
      price: 590.0,
    },
    plus: {
      name: "Plan Plus",
      price: 790.0,
    },
    premium: {
      name: "Plan Premium",
      price: 990.0,
    }
  }.freeze


  SmsPrices = {
    100 => {
      name: "100 SMS",
      cantidad: 100,
      unit_price: 1.5,
      price: 150.0
    },
    250 => {
      name: "250 SMS",
      cantidad: 250,
      unit_price: 1.3,
      price: 325.0
    },
    500 => {
      name: "500 SMS",
      cantidad: 500,
      unit_price: 1.1,
      price: 550.0
    },
    1000 => {
      name: "1000 SMS",
      cantidad: 1000,
      unit_price: 0.9,
      price: 900.0
    }
  }.freeze

  TimbrePrices = {
    100 => {
      name: "100 Timbres",
      cantidad: 100,
      unit_price: 1.5,
      price: 150.0
    },
    250 => {
      name: "250 Timbres",
      cantidad: 250,
      unit_price: 1.3,
      price: 325.0
    },
    500 => {
      name: "500 Timbres",
      cantidad: 500,
      unit_price: 1.1,
      price: 550.0
    },
    1000 => {
      name: "1000 Timbres",
      cantidad: 1000,
      unit_price: 0.9,
      price: 900.0
    }
  }.freeze

  def full_name
    "#{razon} #{rfc}"
  end


  private

  def key_pass_if_key_cer
    if key.attached? && cer.attached? && key_pass.blank?
      errors.add(:key_pass, "La contraseña del certificado es requerida si se han subido el .key y el .cer")
    end
  end
end
