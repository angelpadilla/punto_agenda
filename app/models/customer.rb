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

  Canales = [
    [ "Web", :web ],
    [ "Interno", :interno ]
  ]

  TelPrefixes = {
    # América del Norte
    "+52"  => "🇲🇽 México",
    "+1"   => "🇺🇸 Estados Unidos / Canadá",
    # América Central
    "+502" => "🇬🇹 Guatemala",
    "+503" => "🇸🇻 El Salvador",
    "+504" => "🇭🇳 Honduras",
    "+505" => "🇳🇮 Nicaragua",
    "+506" => "🇨🇷 Costa Rica",
    "+507" => "🇵🇦 Panamá",
    "+53"  => "🇨🇺 Cuba",
    "+509" => "🇭🇹 Haití",
    # América del Sur
    "+57"  => "🇨🇴 Colombia",
    "+58"  => "🇻🇪 Venezuela",
    "+51"  => "🇵🇪 Perú",
    "+593" => "🇪🇨 Ecuador",
    "+54"  => "🇦🇷 Argentina",
    "+56"  => "🇨🇱 Chile",
    "+591" => "🇧🇴 Bolivia",
    "+595" => "🇵🇾 Paraguay",
    "+598" => "🇺🇾 Uruguay",
    "+55"  => "🇧🇷 Brasil",
    "+592" => "🇬🇾 Guyana",
    "+597" => "🇸🇷 Surinam",
    # Europa
    "+34"  => "🇪🇸 España",
    "+44"  => "🇬🇧 Reino Unido",
    "+33"  => "🇫🇷 Francia",
    "+49"  => "🇩🇪 Alemania",
    "+39"  => "🇮🇹 Italia",
    "+351" => "🇵🇹 Portugal",
    "+31"  => "🇳🇱 Países Bajos",
    "+32"  => "🇧🇪 Bélgica",
    "+41"  => "🇨🇭 Suiza",
    "+43"  => "🇦🇹 Austria",
    "+46"  => "🇸🇪 Suecia",
    "+47"  => "🇳🇴 Noruega",
    "+45"  => "🇩🇰 Dinamarca",
    "+358" => "🇫🇮 Finlandia",
    "+353" => "🇮🇪 Irlanda",
    "+30"  => "🇬🇷 Grecia",
    "+48"  => "🇵🇱 Polonia",
    "+36"  => "🇭🇺 Hungría",
    "+40"  => "🇷🇴 Rumanía",
    "+420" => "🇨🇿 República Checa",
    "+421" => "🇸🇰 Eslovaquia",
    "+7"   => "🇷🇺 Rusia",
    "+380" => "🇺🇦 Ucrania",
    "+375" => "🇧🇾 Bielorrusia",
    "+370" => "🇱🇹 Lituania",
    "+371" => "🇱🇻 Letonia",
    "+372" => "🇪🇪 Estonia",
    "+385" => "🇭🇷 Croacia",
    "+381" => "🇷🇸 Serbia",
    "+387" => "🇧🇦 Bosnia y Herzegovina",
    "+386" => "🇸🇮 Eslovenia",
    "+382" => "🇲🇪 Montenegro",
    "+389" => "🇲🇰 Macedonia del Norte",
    "+383" => "🇽🇰 Kosovo",
    "+373" => "🇲🇩 Moldavia",
    "+374" => "🇦🇲 Armenia",
    "+994" => "🇦🇿 Azerbaiyán",
    "+995" => "🇬🇪 Georgia",
    "+376" => "🇦🇩 Andorra",
    "+377" => "🇲🇨 Mónaco",
    "+378" => "🇸🇲 San Marino",
    # Asia
    "+91"  => "🇮🇳 India",
    "+86"  => "🇨🇳 China",
    "+81"  => "🇯🇵 Japón",
    "+82"  => "🇰🇷 Corea del Sur",
    "+65"  => "🇸🇬 Singapur",
    "+60"  => "🇲🇾 Malasia",
    "+66"  => "🇹🇭 Tailandia",
    "+62"  => "🇮🇩 Indonesia",
    "+63"  => "🇵🇭 Filipinas",
    "+84"  => "🇻🇳 Vietnam",
    "+92"  => "🇵🇰 Pakistán",
    "+880" => "🇧🇩 Bangladesh",
    "+90"  => "🇹🇷 Turquía",
    "+966" => "🇸🇦 Arabia Saudita",
    "+971" => "🇦🇪 Emiratos Árabes Unidos",
    "+972" => "🇮🇱 Israel",
    # Oceanía
    "+61"  => "🇦🇺 Australia",
    "+64"  => "🇳🇿 Nueva Zelanda",
    # África
    "+27"  => "🇿🇦 Sudáfrica",
    "+20"  => "🇪🇬 Egipto",
    "+234" => "🇳🇬 Nigeria",
    "+212" => "🇲🇦 Marruecos",
    "+213" => "🇩🇿 Argelia",
    "+254" => "🇰🇪 Kenia",
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

  def facturacion?
    if self.cp.present? and self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present?
      true
    else
      false
    end
  end
  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id tipo tel razon rfc estado deuda_total canal]
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
