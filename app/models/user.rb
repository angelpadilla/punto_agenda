class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable, :trackable

  ## Scopes
  scope :default, -> { order(name: :asc) }
  scope :admins, -> { where(tipo: "admin") }
  scope :users, -> { where(tipo: "user") }

  scope :actives, -> { default.where(active: true) }
  scope :inactives, -> { where(active: false) }

  Tipos = [
    [ "Administrador (acceso a todas la herramientas)", "admin" ],
    [ "Usuario normal", "usuario" ]
  ]


  def admin?
    tipo == "admin"
  end

  def user?
    tipo == "usuario" or tipo == "admin"
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
    %w[id name tipo email phone]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
