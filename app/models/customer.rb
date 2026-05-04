class Customer < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable, :lockable, :trackable

  has_many_attached :docs, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_many :events, dependent: :nullify

  belongs_to :corp, optional: true

  enum :tipo, publico: 0, mayorista: 1

  TelPrefixes = {
    "+52" => "Mexico",
    "+1" => "Estados Unidos",
    "+44" => "Reino Unido",
    "+34" => "España",
    "+91" => "India",
    "+81" => "Japón",
    "+49" => "Alemania",
    "+33" => "Francia",
    "+55" => "Brasil",
    "+61" => "Australia",
    "+86" => "China",
    "+7" => "Rusia",
    "+39" => "Italia",
    "+27" => "Sudáfrica",
    "+82" => "Corea del Sur",
    "+46" => "Suecia",
    "+31" => "Países Bajos",
    "+41" => "Suiza",
    "+64" => "Nueva Zelanda",
    "+65" => "Singapur",
    "+90" => "Turquía",
    "+48" => "Polonia",
    "+20" => "Egipto",
    "+47" => "Noruega",
    "+43" => "Austria",
    "+32" => "Bélgica",
    "+351" => "Portugal",
    "+358" => "Finlandia",
    "+420" => "República Checa",
    "+421" => "Eslovaquia",
    "+386" => "Eslovenia",
    "+370" => "Lituania",
    "+371" => "Letonia",
    "+373" => "Moldavia",
    "+374" => "Armenia",
    "+375" => "Bielorrusia",
    "+376" => "Andorra",
    "+377" => "Mónaco",
    "+378" => "San Marino",
    "+379" => "Vaticano",
    "+380" => "Ucrania",
    "+381" => "Serbia",
    "+382" => "Montenegro",
    "+383" => "Kosovo",
    "+385" => "Croacia",
    "+386" => "Eslovenia",
    "+387" => "Bosnia y Herzegovina",
    "+389" => "Macedonia del Norte",
    "+420" => "Republica Checa",
    "+421" => "Eslovaquia",
    "+386" => "Eslovenia",
    "+370" => "Lituania",
    "+371" => "Letonia",
    "+373" => "Moldavia",
    "+374" => "Armenia",
    "+375" => "Bielorrusia",
    "+376" => "Andorra",
    "+377" => "Monaco",
    "+378" => "San Marino",
    "+379" => "Vaticano",
    "+380" => "Ucrania",
    "+381" => "Serbia",
    "+382" => "Montenegro",
    "+383" => "Kosovo",
    "+385" => "Croacia",
    "+386" => "Eslovenia",
    "+387" => "Bosnia y Herzegovina",
    "+389" => "Macedonia del Norte",
  }.freeze

  validates :razon, :tel, :tel_prefix, presence: true
  validates :tipo, presence: { message: "El tipo de cliente es requerido" }
  validates :tel, format: { with: /\A\d+\z/, message: "Teléfono debe ser un número" }
  validates :tel_prefix, inclusion: { in: TelPrefixes.keys, message: "Prefijo internacional no válido" }
  validates :tel, length: { maximum: 10, message: "Teléfono debe tener máximo 10 dígitos" }
  validates :tel, uniqueness: { scope: :corp_id, message: "Teléfono ya ha sido tomado" }
  validates :email, uniqueness: { scope: :corp_id, case_sensitive: false, message: "Email ya ha sido tomado" }
  validates :cp, length: { maximum: 5, message: "C.P. debe tener máximo 5 dígitos" }
  validates :cp, numericality: { only_integer: true, message: "C.P. debe ser numérico" }, allow_blank: true
  validates :corp_id, presence: { message: "La empresa es obligatoria" }

  normalizes :razon, with: ->(item) { item.strip.downcase.titleize }
  normalizes :rfc, with: ->(item) { item.strip.upcase }

  scope :default, -> { order(razon: :asc) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :con_vencidas, -> {
    # joins(:orders).where("orders.status = ? AND orders.tipo IN (?) AND orders.deadline < ?", "credito", [ "remision", "factura" ], Date.today).distinct
    joins(:orders)
      .where(orders: { status: :credito, tipo: [ :remision, :factura ] })
      .where("orders.deadline <= ?", Date.today)
      .distinct
  }
  scope :sin_vencidas, -> {
    joins(:orders)
      .where(orders: { status: :credito, tipo: [ :remision, :factura ] })
      .where("orders.deadline > ?", Date.today)
      .distinct
  }

  # Scope para ordenar por cantidad de vencidas
  scope :order_by_vencidas, -> {
    joins(:orders)
      .where(orders: { status: :credito, tipo: [ :remision, :factura ] })
      .where("orders.deadline <= ?", Date.today)
      .group("customers.id")
      .select("customers.*, COUNT(orders.id) as vencidas_count")
      # .order("customers.id DESC")
      .order("COUNT(orders.id) DESC") ## Si quieres ordenar por cantidad de vencidas en lugar de por ID del cliente
  }

  # Enum for tipo

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id tipo tel razon rfc estado deuda_total]
  end

  # Add this method to whitelist explicit associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    %w[orders corp]
  end

  before_validation :check_sat

  def deuda_total
    self.orders.where(status: :credito, tipo: [ :remision, :factura ]).sum(:debe)
  end

  def deuda_sin_vencer
    self.orders.where(status: :credito, tipo: [ :remision, :factura ]).where("deadline >= ?", Date.today).sum(:debe)
  end

  def deuda_vencida
    self.orders.where(status: :credito, tipo: [ :remision, :factura ]).where("deadline < ?", Date.today).sum(:debe)
  end

  def limite_restante
    (self.limite_credito || 0) - self.deuda_total
  end

  def ordenes_vencidas
    self.orders.where(status: :credito, tipo: [ :remision, :factura ]).where("deadline < ?", Date.today)
  end

  def last_order_at
    self.orders.order(created_at: :desc).last&.created_at
  end

  def last_event_at
    self.events.order(created_at: :desc).last&.created_at
  end

  

  private

  def check_sat
    if self.regimen != "616"
      errors.add(:rfc, "El RFC es requerido") if self.rfc.blank?
      errors.add(:cp, "El C.P. es requerido") if self.cp.blank?
    end
  end
end
