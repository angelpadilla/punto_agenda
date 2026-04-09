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

  validates :razon, :tel, presence: true
  validates :tipo, presence: { message: "El tipo de cliente es requerido" }
  validates :tel, format: { with: /\A\d+\z/, message: "Teléfono debe ser un número" }
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
