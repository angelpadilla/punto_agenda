class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :trackable
  
  audited max_audits: 1000

  belongs_to :corp, optional: true

  has_many :events, dependent: :nullify
  has_many :orders, dependent: :nullify

  ## has many orders as seller, through :seller_id
  has_many :sales, class_name: "Order", foreign_key: "seller_id", dependent: :nullify

  ## Validations
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :full_name, with: ->(n) { n.strip.downcase.titleize }
  validates :tipo, inclusion: { in: %w[propietario administrador colaborador] }
  # validates :tipo, presence: { message: "El tipo de usuario es requerido" }
  
  validates :full_name, presence: { message: "es requerido" }
  validates :email, presence: { message: "es requerido" }
  validates :email, uniqueness: { message: "ya ha sido tomado por alguien más" }
  
  validates :tel, :tel_prefix, presence: true
  validates :tel_prefix, inclusion: { in: Customer::TelPrefixes.keys, message: "Prefijo no válido" }
  validates :tel, format: { with: /\A\d+\z/, message: "debe ser un número" }
  validates :tel, length: { maximum: 10, message: "debe tener máximo 10 dígitos" }
  validates :tel, uniqueness: { scope: :corp_id, message: "ya ha sido tomado por alguien más" }

  ## Scopes
  scope :default, -> { order(full_name: :asc) }
  scope :props, -> { where(tipo: "prop") }
  scope :admins, -> { where(tipo: "admin") }
  scope :colaboradores, -> { where(tipo: "colaborador") }

  scope :actives, -> { default.where(active: true) }
  scope :inactives, -> { where(active: false) }

  Tipos = [
    [ "Propietario", "propietario" ],
    [ "Administrador", "administrador" ],
    [ "Usuario editor", "colaborador" ],
  ]

  Tipos2 = [
    [ "Administrador", "administrador" ],
    [ "Colaborador", "colaborador" ],
  ]


  def prop?
    tipo == "propietario"
  end

  def admin?
    tipo == "administrador" or tipo == "propietario"
  end

  def colaborador?
    tipo == "colaborador"
  end

  # def can_view?(model)
  #   ## model lo introducen como simbolo, convertir a string y capitalizar
  #   model = model.to_s.strip.downcase.capitalize
  #   if self.prop?
  #     true
  #   elsif self.cargo.roles.where(model: model, action: "ver").exists?
  #     true
  #   else
  #     false
  #   end
  # end

  # def can_create?(model)
  #   model = model.to_s.strip.downcase.capitalize
  #   if self.prop?
  #     true
  #   elsif self.cargo.roles.where(model: model, action: "crear").exists?
  #     true
  #   else
  #     false
  #   end
  # end

  # def can_edit?(model)
  #   model = model.to_s.strip.downcase.capitalize
  #   if self.prop?
  #     true
  #   elsif self.cargo.roles.where(model: model, action: "editar").exists?
  #     true
  #   else
  #     false
  #   end
  # end

  # def can_delete?(model)
  #   model = model.to_s.strip.downcase.capitalize
  #   if self.prop?
  #     true
  #   elsif self.cargo.roles.where(model: model, action: "destruir").exists?
  #     true
  #   else
  #     false
  #   end
  # end

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name tipo email tel active]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
