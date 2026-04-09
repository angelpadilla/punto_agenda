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
end
