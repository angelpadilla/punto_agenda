# bin/rails telegram:poll
# Polling para desarrollo local — pregunta a Telegram cada segundo si hay mensajes
# Producción usa webhook en vez de polling
namespace :telegram do
  desc "Start Telegram bot polling (for local dev)"
  task poll: :environment do
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    abort "❌ No hay telegram.bot_token en credentials" unless token

    puts "🤖 Telegram polling iniciado para @#{Rails.application.credentials.dig(:telegram, :bot_username)} (Ctrl+C para detener)..."

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        begin
          update = message.deep_symbolize_keys
          text = update.dig(:message, :text).to_s
          chat_id = update.dig(:message, :chat, :id)

          if text.start_with?("/start ")
            link_token = text.sub("/start ", "").strip
            corp = Corp.find_by(telegram_link_token: link_token)
            if corp
              corp.update!(telegram_id: chat_id, telegram_link_token: nil, telegram_linked_at: Time.current)
              bot.api.send_message(chat_id: chat_id, text: "✅ ¡Vinculado! #{corp.name} ya está conectado a Telegram.")
              puts "✅ Corp #{corp.id} (#{corp.name}) vinculado — chat_id: #{chat_id}"
            else
              bot.api.send_message(chat_id: chat_id, text: "❌ Link inválido o ya usado. Genera uno nuevo desde tu panel de MiiNegocio.")
              puts "❌ Token no encontrado: #{link_token}"
            end
          elsif text.strip == "/start"
            bot.api.send_message(chat_id: chat_id, text: "👋 ¡Hola! Usa el link de vinculación desde tu panel de MiiNegocio para conectar tu negocio.")
          end
        rescue => e
          puts "🚫 Error: #{e.message}"
        end
      end
    end
  end
end
