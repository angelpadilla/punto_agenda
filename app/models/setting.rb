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

  MontoMinimoRetiro = 500.0

  PlanPrices = {
    basico: {
      name: "Plan Básico",
      price: 390.0,
      items: 50,
      users: 1
    },
    plus: {
      name: "Plan Plus",
      price: 690.0,
      items: 100,
      users: 5
    },
    premium: {
      name: "Plan Premium",
      price: 990.0,
      items: 1000000,
      users: 10
    }
  }.freeze


  SmsPrices = {
    100 => {
      name: "100 SMS",
      cantidad: 100,
      unit_price: 1.5,
      price: 150.0
    },
    250 => {
      name: "250 SMS",
      cantidad: 250,
      unit_price: 1.3,
      price: 325.0
    },
    500 => {
      name: "500 SMS",
      cantidad: 500,
      unit_price: 1.1,
      price: 550.0
    },
    1000 => {
      name: "1000 SMS",
      cantidad: 1000,
      unit_price: 0.9,
      price: 900.0
    }
  }.freeze

  TimbrePrices = {
    100 => {
      name: "100 Timbres",
      cantidad: 100,
      unit_price: 1.5,
      price: 150.0
    },
    250 => {
      name: "250 Timbres",
      cantidad: 250,
      unit_price: 1.3,
      price: 325.0
    },
    500 => {
      name: "500 Timbres",
      cantidad: 500,
      unit_price: 1.1,
      price: 550.0
    },
    1000 => {
      name: "1000 Timbres",
      cantidad: 1000,
      unit_price: 0.9,
      price: 900.0
    }
  }.freeze

  ClaveBancos = {
    "002" => "banamex",
    "006" => "bancomext",
    "009" => "banobras",
    "012" => "bbva bancomer",
    "014" => "santander",
    "019" => "banjercito",
    "021" => "hsbc",
    "030" => "bajio",
    "032" => "ixe",
    "036" => "inbursa",
    "037" => "interacciones",
    "042" => "mifel",
    "044" => "scotiabank",
    "058" => "banregio",
    "059" => "invex",
    "060" => "bansi",
    "062" => "afirme",
    "072" => "banorte",
    "102" => "the royal bank",
    "103" => "american express",
    "106" => "bamsa",
    "108" => "tokyo",
    "110" => "jp morgan",
    "112" => "bmonex",
    "113" => "ve por mas",
    "116" => "ing",
    "124" => "deutsche",
    "126" => "credit suisse",
    "127" => "azteca",
    "128" => "autofin",
    "129" => "barclays",
    "130" => "compartamos",
    "131" => "banco famsa",
    "132" => "bmultiva",
    "133" => "actinver",
    "134" => "wal-mart",
    "135" => "nafin",
    "136" => "interbanco",
    "137" => "bancoppel",
    "138" => "abc capital",
    "139" => "ubs bank",
    "140" => "consubanco",
    "141" => "volkswagen",
    "143" => "cibanco",
    "145" => "bbase",
    "166" => "bansefi",
    "168" => "hipotecaria federal",
    "600" => "monexcb",
    "601" => "gbm",
    "602" => "masari",
    "605" => "value",
    "606" => "estructuradores",
    "607" => "tiber",
    "608" => "vector",
    "610" => "b&b",
    "614" => "accival",
    "615" => "merrill lynch",
    "616" => "finamex",
    "617" => "valmex",
    "618" => "unica",
    "619" => "mapfre",
    "620" => "profuturo",
    "621" => "cb actinver",
    "622" => "oactin",
    "623" => "skandia",
    "626" => "cbdeutsche",
    "627" => "zurich",
    "628" => "zurichvi",
    "629" => "su casita",
    "630" => "cb intercam",
    "631" => "ci bolsa",
    "632" => "bulltick cb",
    "633" => "sterling",
    "634" => "fincomun",
    "636" => "hdi seguros",
    "637" => "order",
    "638" => "akala",
    "640" => "cb jpmorgan",
    "642" => "reforma",
    "646" => "stp",
    "647" => "telecomm",
    "648" => "evercore",
    "649" => "skandia",
    "651" => "segmty",
    "652" => "asea",
    "653" => "kuspit",
    "655" => "sofiexpress",
    "656" => "unagra",
    "659" => "opciones empresariales del noroeste",
    "670" => "libertad",
    "901" => "cls",
    "902" => "indeval",
    "999" => "n/a"
  }

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
