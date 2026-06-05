class CobranzaJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Iniciando cobranza diaria para todos los Corps..."
    Gtools.cobranza
    puts "Cobranza diaria completada para todos los Corps."
  end
end
