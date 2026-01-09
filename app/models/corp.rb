class Corp < ApplicationRecord
  audited max_audits: 100
  has_many :users

  has_one_attached :key, dependent: :destroy
  has_one_attached :cer, dependent: :destroy
  has_one_attached :logo, dependent: :destroy

  has_many :orders, dependent: :destroy
  has_many :items, dependent: :destroy

  validates :razon, :rfc, :regimen, :estado, :cp, :ciudad, :colonia, :calle, :num_ext, :phone, presence: true
  validates :cp, numericality: true, length: { is: 5 }
  validates :rfc, length: { in: 10..13 }

  normalizes :name, :razon, :cp, :ciudad, :colonia, :localidad, :calle, :num_ext, :num_int, :phone, with: ->(e) { e.strip }
  normalizes :rfc, with: ->(e) { e.strip.upcase }

  def self.ransackable_attributes(auth_object = nil)
    %W[id name razon rfc regimen]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  def full_name
    "#{razon} #{rfc}"
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
end
