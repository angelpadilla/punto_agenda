# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


SatProduct.create(
  [
    { sku: "01010101", name: "No existe en el catálogo" },
    { sku: "10101500", name: "Animales vivos de granja" },
    { sku: "10101501", name: "Gatos vivos" },
    { sku: "10101502", name: "Perros" },
    { sku: "10101504", name: "Visón" },
    { sku: "10101505", name: "Ratas" },
    { sku: "10101506", name: "Caballos" }
  ]
)