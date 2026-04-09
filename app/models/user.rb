class User < ApplicationRecord
  audited max_audits: 100
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :trackable


  belongs_to :corp, optional: true

  has_many :events, dependent: :nullify

  ## Validations
  normalizes :email, with: ->(e) { e.strip.downcase }
  validates :tipo, inclusion: { in: %w[admin usuario] }
  # validates :tipo, presence: { message: "El tipo de usuario es requerido" }
  validates :full_name, presence: { message: "El Nombre es requerido" }
  validates :email, presence: { message: "El Email es requerido" }
  validates :email, uniqueness: { message: "El Email ya ha sido tomado por alguien más" }
  validates :tel, presence: { message: "Teléfono es requerido" }
  validates :tel, numericality: { only_integer: true, message: "Teléfono debe ser un número" }
  validates :tel, length: { maximum: 10, message: "Teléfono debe tener máximo 10 dígitos" }
  validates :tel, uniqueness: { message: "Teléfono ya ha sido tomado por alguien más" }

  ## Scopes
  scope :default, -> { order(full_name: :asc) }
  scope :admins, -> { where(tipo: "admin") }
  scope :users, -> { where(tipo: "usuario") }

  scope :actives, -> { default.where(active: true) }
  scope :inactives, -> { where(active: false) }

  Tipos = [
    [ "Administrador (acceso a todas la herramientas)", "admin" ],
    [ "Usuario editor (no puede eliminar objetos)", "editor" ],
    [ "Usuario básico (solo puede ver)", "usuario" ]
  ]


  def admin?
    tipo == "admin"
  end

  def editor?
    tipo == "editor" or tipo == "admin"
  end

  def basic?
    tipo == "usuario"
  end

  def can_view?(model)
    ## model lo introducen como simbolo, convertir a string y capitalizar
    model = model.to_s.strip.downcase.capitalize
    if self.admin?
      true
    elsif self.cargo.roles.where(model: model, action: "ver").exists?
      true
    else
      false
    end
  end

  def can_create?(model)
    model = model.to_s.strip.downcase.capitalize
    if self.admin?
      true
    elsif self.cargo.roles.where(model: model, action: "crear").exists?
      true
    else
      false
    end
  end

  def can_edit?(model)
    model = model.to_s.strip.downcase.capitalize
    if self.admin?
      true
    elsif self.cargo.roles.where(model: model, action: "editar").exists?
      true
    else
      false
    end
  end

  def can_delete?(model)
    model = model.to_s.strip.downcase.capitalize
    if self.admin?
      true
    elsif self.cargo.roles.where(model: model, action: "destruir").exists?
      true
    else
      false
    end
  end

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name tipo email tel active]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
