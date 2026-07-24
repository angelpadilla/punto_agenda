class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :trackable

  audited max_audits: 1000, except: [
    :encrypted_password,
    :reset_password_token,
    :reset_password_sent_at,
    :remember_created_at,
    :sign_in_count,
    :current_sign_in_at,
    :last_sign_in_at,
    :current_sign_in_ip,
    :last_sign_in_ip,
    :failed_attempts,
    :unlock_token,
    :locked_at
  ]

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
    [ "Usuario editor", "colaborador" ]
  ]

  Tipos2 = [
    [ "Administrador", "administrador" ],
    [ "Colaborador", "colaborador" ]
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

  def work_hours_default?
    return true if work_start_time.blank? && work_end_time.blank?

    work_start_time.present? &&
      work_end_time.present? &&
      work_start_time.hour == 0 &&
      work_start_time.min == 0 &&
      work_end_time.hour == 23 &&
      work_end_time.min == 59
  end

  def work_hours_customized?
    work_start_time.present? && work_end_time.present? && !work_hours_default?
  end

  # ¿Este agente trabaja durante el slot dado?
  # Si no tiene work_start_time/work_end_time definidos, se asume que trabaja todo el día
  # @param slot_start [Time] inicio del slot
  # @param slot_end [Time] fin del slot
  # @return [Boolean]
  def works_during?(slot_start, slot_end)
    return true if work_start_time.blank? || work_end_time.blank?

    # Convertir horas a minutos desde medianoche para comparar sin fecha
    work_start_mins = work_start_time.hour * 60 + work_start_time.min
    work_end_mins   = work_end_time.hour * 60 + work_end_time.min
    slot_start_mins = slot_start.hour * 60 + slot_start.min
    slot_end_mins   = slot_end.hour * 60 + slot_end.min

    # El slot debe estar completamente dentro del horario del agente
    slot_start_mins >= work_start_mins && slot_end_mins <= work_end_mins
  end

  after_create :send_welcome_email

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name tipo email tel active]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  ## funcion para eliminar usuarios que no tienen corp asociado
  def self.cleanup_orphaned_users
    where(corp_id: nil).destroy_all
  end

  def send_welcome_email
    UserMailer.with(user: self).welcome_email.deliver_later
  end
end
