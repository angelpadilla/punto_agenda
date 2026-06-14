namespace :corps do
  desc "Migra business_hours de todos los Corps al nuevo formato {active, hours:[{open,close}]}"
  task normalize_business_hours: :environment do
    migrated = 0
    skipped  = 0
    errors   = 0

    Corp.find_each do |corp|
      bh = corp.business_hours
      next if bh.blank?

      needs_migration = bh.any? do |_wday, cfg|
        cfg.is_a?(Hash) && !cfg.key?("hours")
      end

      unless needs_migration
        puts "🪃 [SKIP] Corp##{corp.id} - #{corp.name}" if ENV["VERBOSE"]
        skipped += 1
        next
      end

      corp.business_hours_will_change!

      bh.each do |_wday, cfg|
        next unless cfg.is_a?(Hash) && !cfg.key?("hours")

        open_val  = cfg.delete("open")  || "09:00"
        close_val = cfg.delete("close") || "18:00"
        cfg["hours"] = [ { "open" => open_val, "close" => close_val } ]
      end

      corp.business_hours = bh

      if corp.save(validate: false)
        puts "✅    Corp##{corp.id} - #{corp.name}"
        migrated += 1
      else
        puts "❌ Corp##{corp.id} - #{corp.name}: #{corp.errors.full_messages.join(', ')}"
        errors += 1
      end
    rescue => e
      puts "❌ Corp##{corp.id} - #{corp.name}: #{e.message}"
      errors += 1
    end

    puts "✅ Listo: #{migrated} migrados, #{skipped} ya actualizados, #{errors} errores."
  end

  desc "Ejecuta cobranza diaria para todos los Corps (genera bills, manda correos, etc)"
  task cobranza: :environment do
    puts "Iniciando cobranza diaria para todos los Corps..."
    Gtools.cobranza
    puts "----------------------------------"
    puts "Cobranza diaria completada para todos los Corps."
  end
end
