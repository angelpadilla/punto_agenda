class Provider < ApplicationRecord
  belongs_to :corp

  validates :razon, :tel, presence: true
  validates :tel, format: { with: /\A\d+\z/, message: "Teléfono debe ser un número" }
  validates :tel, length: { maximum: 10, message: "Teléfono debe tener máximo 10 dígitos" }
  validates :tel, uniqueness: { scope: :corp_id, message: "Teléfono ya ha sido tomado" }
  validates :email, uniqueness: { scope: :corp_id, case_sensitive: false, message: "Email ya ha sido tomado" }
  validates :cp, length: { maximum: 5, message: "C.P. debe tener máximo 5 dígitos" }
  validates :cp, numericality: { only_integer: true, message: "C.P. debe ser numérico" }, allow_blank: true

  normalizes :razon, with: ->(item) { item.strip.upcase }
  normalizes :rfc, with: ->(item) { item.strip.upcase }

  scope :default, -> { order(razon: :asc) }

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id tipo tel razon rfc estado]
  end

  # Add this method to whitelist explicit associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[corp]
  end

  before_validation :check_sat

  private

  def check_sat
    if self.regimen != "616"
      errors.add(:rfc, "El RFC es requerido") if self.rfc.blank?
      errors.add(:cp, "El C.P. es requerido") if self.cp.blank?
    end
  end
end
