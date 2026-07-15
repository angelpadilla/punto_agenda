class Corp < ApplicationRecord
  audited max_audits: 100

  has_many :events, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :providers, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :orders, dependent: :destroy
  
  has_many :corp_customers, dependent: :destroy
  has_many :customers, through: :corp_customers
  has_many :bills, dependent: :nullify
  has_many :tickets, dependent: :nullify
  has_many :users, dependent: :destroy

  has_one_attached :key, dependent: :destroy
  has_one_attached :cer, dependent: :destroy
  has_one_attached :logo, dependent: :destroy

  serialize :business_hours, coder: JSON

  DAYS_OF_WEEK = {
    "0" => "Domingo",
    "1" => "Lunes",
    "2" => "Martes",
    "3" => "Miércoles",
    "4" => "Jueves",
    "5" => "Viernes",
    "6" => "Sábado"
  }.freeze

  DEFAULT_BUSINESS_HOURS = {
    "0" => { "active" => false, "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "1" => { "active" => true,  "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "2" => { "active" => true,  "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "3" => { "active" => true,  "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "4" => { "active" => true,  "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "5" => { "active" => true,  "hours" => [ { "open" => "09:00", "close" => "18:00" } ] },
    "6" => { "active" => false, "hours" => [ { "open" => "09:00", "close" => "18:00" } ] }
  }.freeze

  enum :tipo_plan, basico: 0, plus: 1, premium: 2
  enum :status, activo: "activo", probando: "probando", suspendido: "suspendido", moroso: "moroso"


  TipoNegocios = [
    [ "💊 Salud", "salud" ],
    [ "💈 Barberia", "barberia" ],
    [ "💇‍♀️ Salon de belleza", "salon_belleza" ],
    [ "☕ Cafetería", "cafeteria" ],
    [ "🛠️ Servicios", "servicios" ],
    [ "❓ Otro", "otro" ]
  ].freeze

  validates :tipo_negocio, presence: { message: "El tipo de negocio es requerido" }, inclusion: { in: TipoNegocios.map(&:last), message: "Tipo de negocio no válido" }

  validates :name, :phone, :tel_prefix, presence: true, on: :update
  validates :email, presence: true, on: :update

  validates :tel_prefix, inclusion: { in: Customer::TelPrefixes.keys, message: "Prefijo no válido" }
  validates :phone, format: { with: /\A\+?\d+\z/, message: "Teléfono debe ser un número valido" }
  validates :phone, length: { maximum: 10, message: "Teléfono debe tener máximo 10 dígitos" }
  validates :min_book_amount, numericality: { greater_than_or_equal_to: 100, message: "El monto mínimo debe ser al menos $100.00 MXN" }, allow_blank: true

  # validates :banco_clabe, presence: { message: "La CLABE es requerida" }, if: :online_payments?
  validates :banco_clabe, format: { with: /\A\d{18}\z/, message: "La CLABE debe ser un número de 18 dígitos" }, allow_blank: true
  # validates :banco_beneficiario, presence: { message: "El nombre del beneficiario es requerido" }, if: :online_payments?

  # validates :whatsapp, format: { with: /\A\+?\d+\z/, message: "Teléfono debe ser un número valido" }, allow_blank: true
  # validates :whatsapp, length: { maximum: 15, message: "Teléfono debe tener máximo 15 dígitos" }, allow_blank: true

  # validates :razon, :rfc, :regimen, :estado, :cp, :ciudad, :colonia, :calle, :num_ext, presence: true, if: :facturacion?, on: :update
  ## custom validator
  validate :facturacion_datos
  validate :key_pass_if_key_cer
  validate :business_hours_no_overlap
  validates :cp, numericality: true, length: { is: 5 }, on: :update, if: :facturacion?
  validates :rfc, length: { in: 10..13 }, on: :update, if: :facturacion?

  validates :key, content_type: ".key", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :cer, content_type: ".cer", size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update
  validates :logo, content_type: [ "image/png", "image/jpeg" ], size: { less_than: 5.megabytes, message: "El archivo debe ser menor a 5MB" }, allow_blank: true, on: :update

  normalizes :name, :razon, :cp, :ciudad, :colonia, :localidad, :calle, :num_ext, :num_int, :phone, with: ->(e) { e.strip.downcase }
  normalizes :rfc, with: ->(e) { e.strip.upcase }

  scope :default, -> { order(created_at: :desc) }
  scope :activos, -> { where(status: [ :activo, :probando, :moroso ]) }

  def deposits
    Deposit.where(depositable: orders)
          .or(Deposit.where(depositable: purchases))
  end

  def self.ransackable_attributes(auth_object = nil)
    %W[id name razon rfc regimen sku]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  def balance
    # deposits.where(status_pago: :pagado, canal: :stripe)
    #         .sum("deposits.monto - deposits.comision_terminal - deposits.comision_sitio") || 0.0
    deposits.where(status_pago: :pagado, canal: :stripe).sum { |d| d.monto - d.comision_terminal - d.comision_sitio } || 0.0
  end

  def last_for_retiro
    bills.where(direccion: :egreso).last
  end

  def full_name
    "#{razon} #{rfc}"
  end

  def full_tel
    "#{tel_prefix} #{phone}"
  end

  def facturacion?
    if self.facturacion and self.cp.present? and self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present? and self.key_pass.present? and self.key.attached? and self.cer.attached?
      true
    else
      false
    end
  end

  def fac_and_timbres?
    if self.facturacion and self.cp.present? and self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present? and self.key_pass.present? and self.key.attached? and self.cer.attached? and self.timbres > 0
      true
    else
      false
    end
  end

  def me_pueden_facturar?
    if self.rfc.present? and self.razon.present? and self.regimen.present? and self.estado.present? and self.cp.present?
      true
    else
      false
    end
  end

  def corp_ready?
    if self.name.present? and self.email.present? and self.tipo_negocio.present? and self.phone.present? and self.tel_prefix.present? and self.logo.attached?
      true
    else
      false
    end
  end

  def spei?
    if self.banco_clabe.present? and self.banco_nombre.present? and self.banco_beneficiario.present?
      true
    else
      false
    end
  end

  def business_hours_no_overlap
    return if business_hours.blank?

    business_hours.each do |wday, cfg|
      next unless cfg.is_a?(Hash) && cfg["active"] == true
      hours = cfg["hours"].presence || []
      next if hours.size < 2

      day_name = Corp::DAYS_OF_WEEK[wday] || "día #{wday}"
      prev_close = nil

      hours.each_with_index do |h, i|
        open_mins  = h["open"].split(":").then  { |hr, m| hr.to_i * 60 + m.to_i }
        close_mins = h["close"].split(":").then { |hr, m| hr.to_i * 60 + m.to_i }

        if close_mins <= open_mins
          errors.add(:business_hours, "#{day_name} slot #{i + 1}: la hora de cierre debe ser posterior a la de apertura")
        end

        if prev_close && open_mins < prev_close
          errors.add(:business_hours, "#{day_name} slot #{i + 1}: la apertura (#{h['open']}) se solapa con el slot anterior")
        end

        prev_close = close_mins
      end
    end
  end

  def facturacion_datos
    if facturacion
      errors.add(:razon, "La razón social es requerida") if razon.blank?
      errors.add(:rfc, "El RFC es requerido") if rfc.blank?
      errors.add(:regimen, "El régimen fiscal es requerido") if regimen.blank?
      errors.add(:estado, "El estado es requerido") if estado.blank?
      errors.add(:cp, "El código postal es requerido") if cp.blank?
      errors.add(:ciudad, "La ciudad es requerida") if ciudad.blank?
      errors.add(:colonia, "La colonia es requerida") if colonia.blank?
      errors.add(:calle, "La calle es requerida") if calle.blank?
      errors.add(:num_ext, "El número exterior es requerido") if num_ext.blank?
    end
  end

  def key_pass_if_key_cer
    if key.attached? && cer.attached? && key_pass.blank?
      errors.add(:key_pass, "La contraseña del certificado es requerida si se han subido el .key y el .cer")
    end
  end


  States = [
    [ "Aguascalientes", "aguascalientes" ],
    [ "Baja California", "baja_california" ],
    [ "Baja California Sur", "baja_california_sur" ],
    [ "Campeche", "campeche" ],
    [ "Coahuila de Zaragoza", "coahuila" ],
    [ "Colima", "colima" ],
    [ "Chiapas", "chiapas" ],
    [ "Chihuahua", "chihuahua" ],
    [ "Distrito Federal", "df" ],
    [ "Durango", "durango" ],
    [ "Guanajuato", "guanajuato" ],
    [ "Guerrero", "guerrero" ],
    [ "Hidalgo", "hidalgo" ],
    [ "Jalisco", "jalisco" ],
    [ "México", "mexico" ],
    [ "Michoacán de Ocampo", "michoacan" ],
    [ "Morelos", "morelos" ],
    [ "Nayarit", "nayarit" ],
    [ "Nuevo León", "nuevo_leon" ],
    [ "Oaxaca", "oaxaca" ],
    [ "Puebla", "puebla" ],
    [ "Querétaro", "queretaro" ],
    [ "Quintana Roo", "quintana_roo" ],
    [ "San Luis Potosí", "san_luis" ],
    [ "Sinaloa", "sinaloa" ],
    [ "Sonora", "sonora" ],
    [ "Tabasco", "tabasco" ],
    [ "Tamaulipas", "tamaulipas" ],
    [ "Tlaxcala", "tlaxcala" ],
    [ "Veracruz", "varacruz" ],
    [ "Yucatán", "yucatan" ],
    [ "Zacatecas", "zacatecas" ]
  ]

  RegimenFiscales = [
    [ "Sin obligaciones fiscales (público en general)", "616" ],
    [ "General de Ley personas Morales", "601" ],
    [ "Personas Físicas con Actividades Empresariales y Profesionales", "612" ],
    [ "Personas Morales con Fines no Lucrativos", "603" ],
    [ "Sueldos y Salarios e Ingresos Asimilados a Salarios", "605" ],
    [ "Arrendamiento", "606" ],
    [ "Demás ingresos", "608" ],
    [ "Consolidación", "609" ],
    [ "Residentes en el Extranjero sin Establecimiento Permanente en México", "610" ],
    [ "Ingresos por Dividendos (socios y accionistas)", "611" ],
    [ "Ingresos por intereses", "614" ],
    [ "Sociedades Cooperativas de Producción que optan por diferir sus ingresos", "620" ],
    [ "Incorporación Fiscal", "621" ],
    [ "Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras", "622" ],
    [ "Opcional para Grupos de Sociedades", "623" ],
    [ "Coordinados", "624" ],
    [ "Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas", "625" ],
    [ "Régimen Simplificado de Confianza", "626" ],
    [ "Régimen de Enajenación o Adquisición de Bienes", "607" ],
    [ "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales", "629" ],
    [ "Enajenación de acciones en bolsa de valores", "630" ],
    [ "Régimen de los ingresos por obtención de premios", "615" ]
  ]

  after_initialize :set_default_business_hours
  before_validation :normalize_business_hours

  before_create :gen_sku
  after_create :create_stripe_customer
  after_create :send_notification

  before_save :check_banco

  def check_banco
    ## sacamos el nombre del banco a partir de la clabe
    if self.banco_clabe.present? and self.banco_beneficiario.present?
      nombre = Setting::ClaveBancos[self.banco_clabe[0..2]]
      if nombre.present?
        self.banco_nombre = nombre.capitalize
      else
        self.banco_nombre = "Otro"
      end
    end
  end

  def working_day?(date)
    return false if business_hours.blank?

    day_config = business_hours[date.in_time_zone.to_date.wday.to_s]
    return false if day_config.nil?

    day_config["active"] == true
  end

  ## Devuelve los slots configurados para un día específico, sin considerar reservas
  # @param date [Date] fecha a evaluar
  # @return [Array<Hash>] array de slots con formato { index: Integer, start: "HH:MM", end: "HH:MM" }
  def slots_for_day(date)
    return [] unless working_day?(date)

    day_config = business_hours[date.in_time_zone.to_date.wday.to_s]
    return [] if day_config.nil?

    (day_config["hours"] || []).each_with_index.map do |h, i|
      { index: i, start: h["open"], end: h["close"] }
    end
  end

  ## Devuelve el numero total de slots disponibles para un día, sin considerar reservas
  # @param date [Date] fecha a evaluar
  # @return [Integer] número total de slots disponibles para ese día
  def slots_per_day(date)
    slots_for_day(date).size
  end

  # Devuelve información de ocupación de slots para un día específico para toda la corp o un usuario (opcional, para mostrar disponibilidad personalizada)
  # @param date [Date] fecha a evaluar
  # @param user_id [Integer, nil] ID del usuario para filtrar disponibilidad personalizada
  # @return [Hash, nil] hash con formato
  #   { total: Integer, disponibles: Integer, ocupados: Integer, pct: Float, first_open: "HH:MM", last_close: "HH:MM",
  #     # total = slots_del_día × num_agentes (capacidad real de citas)
  #     slots: [
  #       { index: Integer, start: "HH:MM", end: "HH:MM", fully_booked: Boolean, available_for_user: Boolean, agentes_libres: Integer, agentes_ocupados: Integer, booked_agents: Array<User>, free_agents: Array<User>, events: Array<Event> },
  #     ]
  #   },
  # o nil si no es día laborable
  def available_slots_for_day(date, user_id: nil)
    all_slots = slots_for_day(date)
    return nil if all_slots.empty?

    date = date.in_time_zone.to_date

    eventss = events.includes(:customer, :user, :orders).where(
      hora_inicio: date.beginning_of_day..date.end_of_day
    )

    booked_events = eventss.where(status: [ :agendado, :completado ]).to_a
    eventss = eventss.to_a

    all_agents       = users.to_a
    all_agent_ids    = all_agents.map(&:id)
    filter_agent_ids = user_id.present? ? [ user_id ] : all_agent_ids
    return nil if all_agent_ids.empty?

    # eventos que caben en al menos un slot actual (los desfasados no deben bloquear agentes)
    matched_booked_ids = booked_events.select { |ev|
      all_slots.any? { |s|
        s_start = Time.zone.parse("#{date} #{s[:start]}")
        s_end   = Time.zone.parse("#{date} #{s[:end]}")
        ev.hora_inicio >= s_start && ev.hora_final <= s_end
      }
    }.map(&:id)

    free_for = ->(uid, slot_start, slot_end) {
      booked_events
        .select { |ev| ev.user_id == uid && matched_booked_ids.include?(ev.id) }
        .none?  { |ev| ev.hora_inicio < slot_end && ev.hora_final > slot_start }
    }

    enriched_slots = all_slots.map do |slot|
      slot_start = Time.zone.parse("#{date} #{slot[:start]}")
      slot_end   = Time.zone.parse("#{date} #{slot[:end]}")

      # agentes que trabajan durante este slot (según su horario personal)
      working_agents    = all_agents.select { |u| u.works_during?(slot_start, slot_end) }
      working_agent_ids = working_agents.map(&:id)
      non_working_agents = all_agents - working_agents
      slot_agent_count  = working_agent_ids.size

      # calcular estado solo para agentes que trabajan en este slot
      agent_free       = working_agent_ids.index_with { |uid| free_for.call(uid, slot_start, slot_end) }
      fully_booked     = slot_agent_count > 0 && agent_free.values.none?
      agentes_libres   = agent_free.count { |_, free| free }
      agentes_ocupados = slot_agent_count - agentes_libres
      booked_agents    = agent_free.filter_map { |uid, free| all_agents.find { |u| u.id == uid } unless free }
      free_agents      = agent_free.filter_map { |uid, free| all_agents.find { |u| u.id == uid } if free }
      available_for_user = filter_agent_ids.any? { |uid| agent_free[uid] }
      # eventos que solapan con el slot (para calcular ocupación de agentes)
      slot_events       = booked_events.select { |ev| ev.hora_inicio < slot_end && ev.hora_final > slot_start }
      # solo eventos contenidos completamente dentro del slot (evita duplicados entre slots)
      slot_events_all    = eventss.select { |ev| ev.hora_inicio >= slot_start && ev.hora_final <= slot_end }

      slot.merge(
        start: slot_start.strftime("%I:%M %p"),
        end: slot_end.strftime("%I:%M %p"),
        range: "#{slot[:start]}|#{slot[:end]}",
        fully_booked: fully_booked,
        available_for_user: available_for_user,
        agentes_activos: slot_agent_count,
        agentes_libres: agentes_libres,
        agentes_ocupados: agentes_ocupados,
        booked_agents: booked_agents,
        free_agents: free_agents,
        non_working_agents: non_working_agents,
        events: slot_events_all
      )
    end

    # total real: suma de agentes activos por slot (respeta horarios personales)
    total       = enriched_slots.sum { |s| s[:agentes_activos] }
    disponibles = enriched_slots.sum { |s| s[:agentes_libres] }
    ocupados    = enriched_slots.sum { |s| s[:agentes_ocupados] }

    # porcentaje de ocupación del dia, redondeado a 1 decimal, evita división por cero
    pct         = total > 0 ? (ocupados * 100.0 / total).round(1) : 0.0

    matched_event_ids = enriched_slots.flat_map { |s| s[:events].map(&:id) }.uniq
    unmatched_events = eventss.reject { |ev| matched_event_ids.include?(ev.id) }

    {
      total:       total,
      disponibles: disponibles,
      ocupados:    ocupados,
      pct:         pct,
      first_open:  Time.parse(all_slots.first[:start]).strftime("%I:%M %p"),
      last_close:  Time.parse(all_slots.last[:end]).strftime("%I:%M %p"),
      slots:       enriched_slots,
      unmatched_events: unmatched_events
    }
  end

  def to_fullcalendar_business_hours
    return [] if business_hours.blank?

    business_hours.flat_map do |wday, config|
      next [] unless config["active"] == true

      (config["hours"] || []).map do |h|
        { daysOfWeek: [ wday.to_i ], startTime: h["open"], endTime: h["close"] }
      end
    end
  end

  def prop
    users.find_by(tipo: "propietario")
  end

  def create_stripe_customer
    return if stripe_customer_id.present?
    client = Stripe::StripeClient.new(Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key))
    customer = client.v1.customers.create({ name: "#{self.name}, corpId: #{self.id}", email: self.email })
    if customer && customer.id
      update(stripe_customer_id: customer.id)
    else
      puts "-- Error creating Stripe customer for Corp #{id}: #{customer.inspect}"
    end
  end

  ## funcion para eliminar las corps que no tienen usuarios 'propietarios' asociados
  def self.cleanup_orphaned_corps
    self.all.each do |corp|
      if corp.prop.nil?
        puts "Eliminando Corp #{corp.id} - #{corp.name} por no tener propietario asociado"
        corp.destroy
      end
    end
  end

  def self.get_corps_cobranza
    noww = Time.current
    where(status: [ :activo, :probando, :moroso ])
      .where(
        "(subscription_trial_end IS NULL OR subscription_trial_end <= ?) AND (subscription_next_billing_date IS NULL OR subscription_next_billing_date <= ?)",
        noww, noww
      )
  end



  private

  def gen_sku
    token = SecureRandom.alphanumeric(5).upcase
    while Corp.where(sku: token).exists?
      token = SecureRandom.alphanumeric(5).upcase
    end
    self.sku = token
  end


  def set_default_business_hours
    self.business_hours ||= DEFAULT_BUSINESS_HOURS.deep_dup
  end

  def normalize_business_hours
    return if business_hours.blank?

    business_hours.each do |_wday, config|
      config["active"] = ActiveModel::Type::Boolean.new.cast(config["active"])

      # hours may arrive as indexed hash from form params → convert to array
      hours = config["hours"]
      if hours.is_a?(Hash)
        config["hours"] = hours.sort_by { |k, _| k.to_i }.map { |_, h| { "open" => h["open"].to_s, "close" => h["close"].to_s } }
      end
      config["hours"] = [ { "open" => "09:00", "close" => "18:00" } ] if config["hours"].blank?
    end
  end

  def send_notification
    # CorpMailer.with(corp: self).new_corp_notification.deliver_later
    Gtools.telegram_noti(message: "Nueva Corp creada: #{name} (ID: #{id}, Tipo negocio: #{tipo_negocio})")
  end
end
