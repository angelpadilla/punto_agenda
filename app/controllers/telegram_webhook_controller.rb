# Public webhook receiver for Telegram bot
# Set webhook: POST to https://miinegocio.com/telegram/webhook
class TelegramWebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    update = params.permit!.to_h
    return render plain: "ok" unless update[:message] || update[:callback_query]

    # Handle /start command with deep link token
    if update[:message] && update[:message][:text]
      text = update[:message][:text].to_s
      chat_id = update[:message][:chat][:id]

      if text.start_with?("/start ")
        token = text.sub("/start ", "").strip
        corp = Corp.find_by(telegram_link_token: token)
        if corp
          corp.update!(telegram_id: chat_id, telegram_link_token: nil, telegram_linked_at: Time.current)
          send_telegram_message(chat_id, "✅ ¡Vinculado! #{corp.name} ya está conectado a Telegram. Recibirás notificaciones aquí.")
        else
          send_telegram_message(chat_id, "❌ Link inválido o ya usado. Genera uno nuevo desde tu panel de MiiNegocio.")
        end
      end
    end

    render plain: "ok"
  end

  private

  def send_telegram_message(chat_id, text)
    bot = Telegram::Bot::Client.new(Rails.application.credentials.dig(:telegram, :bot_token))
    bot.send_message(chat_id: chat_id, text: text)
  rescue => e
    Rails.logger.error("Telegram webhook send error: #{e.message}")
  end
end
