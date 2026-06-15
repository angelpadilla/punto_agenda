class CobranzaJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Iniciando cobranza diaria para todos los Corps..."
    Gtools.cobranza
    Gtools.telegram_noti(message: "Cobranza diaria completada para todos los Corps.")
    puts "Cobranza diaria completada para todos los Corps."
  end
end
