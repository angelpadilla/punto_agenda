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
