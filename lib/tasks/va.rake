## Gen task
# bin/rails generate task my_namespace my_task_name

# Example usage:
# bin/rails va:gen_events

namespace :va do
  desc "Genera unos 100 eventos con faker en este mes para probar el calendario"
  task gen_events: :environment do
    puts "Generando eventos para el calendario..."
    Customer.find_each do |customer|
      rand(1..50).times do
        hora_inicio = Faker::Time.between(from: Date.today.beginning_of_month, to: Date.today.end_of_month)
        Event.create(
          title: "Evento de #{customer.razon}",
          hora_inicio: hora_inicio,
          hora_final: hora_inicio + rand(1..3).hours,
          body: Faker::Lorem.sentence(word_count: 10),
          customer: customer,
          corp: customer.corp,
          user: customer.corp.users.first # Asignar el primer usuario del corp del cliente
        )
      end
    end
    puts "Eventos generados exitosamente."
  end

  desc "Crea un bill dummy con pago simulado en Stripe para probar facturación"
  task dummy_bill: :environment do
    puts "Generando bill dummy..."
    Gtools.do_dummy_bill(corp_id: 1) # Reemplaza 1 con el ID del corp que desees
  end

  desc "Manda notificación de prueba por Telegram"
  task telegram_noti: :environment do
    Gtools.telegram_noti(message: "Mensaje de prueba desde Rake task")
  end
end
