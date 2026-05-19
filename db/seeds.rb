# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# SatProduct.create(
#   [
#     { sku: "01010101", name: "No existe en el catálogo" },
#     { sku: "10101500", name: "Animales vivos de granja" },
#     { sku: "10101501", name: "Gatos vivos" },
#     { sku: "10101502", name: "Perros" },
#     { sku: "10101504", name: "Visón" },
#     { sku: "10101505", name: "Ratas" },
#     { sku: "10101506", name: "Caballos" }
#   ]
# )

Setting.find_or_create_by!(id: 1) do |s|
  s.name = "MiiNegocio"
  s.domain = "miinegocio.com"
  s.email = "contacto@miinegocio.com"
  s.instagram_url = "https://www.instagram.com/miinegocio/"
  s.tiktok_url = "https://www.tiktok.com/@miinegocio"
  s.facebook_url = "https://www.facebook.com/miinegocio"
  s.phone = "3481119725"
  s.tel_prefix = "+52"
  s.estado = "Jalisco"
  s.cp = "47180"
  s.colonia = "Arandas Centro"
  s.ciudad = "Arandas"
  s.localidad = "Arandas"
  s.calle = "Ignacio Mariscal"
  s.num_ext = "78"
  s.num_int ="B"
  s.razon = "Angel Gabriel Padilla Martinez"
  s.rfc = "PAMA891110MP9"
  s.regimen = "612"
end
puts "- Setting creado...."
