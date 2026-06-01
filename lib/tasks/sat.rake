require "json"
namespace :sat do
  desc "Genera unos productos del catálogo SAT para pruebas"
  task gen_products: :environment do
    puts "Generando productos del catálogo SAT..."

    claves_path = Rails.root.join("lib", "tasks", "sat_claves.json")
    claves = JSON.parse(File.read(claves_path))

    claves.each do |clave|
      puts clave
      SatProduct.create(sku: clave["sku"], name: clave["name"])
    end

    puts "Productos del catálogo SAT añadidos exitosamente."
  end
end