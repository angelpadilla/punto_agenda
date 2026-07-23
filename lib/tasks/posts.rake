namespace :posts do
  desc "Importa artículos desde RSS de Soro AI"
  task import_soro: :environment do
    result = SoroRss.run

    puts "Feed: #{result[:feed_url]}"
    puts "Total items: #{result[:total_items]}"
    puts "Creados: #{result[:created]}"
    puts "Duplicados: #{result[:duplicates]}"
    puts "Errores: #{result[:errors]}"

    if result[:error_details].present?
      puts "Detalle de errores:"
      result[:error_details].each do |error|
        puts "- #{error[:title] || 'Sin título'} | #{error[:error]}"
      end
    end

    raise "Importación fallida" unless result[:success]
  end
end