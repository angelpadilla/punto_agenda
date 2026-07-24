# Public webhook receiver for Telegram bot
# Set webhook: POST to https://miinegocio.com/telegram/webhook
class TelegramWebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  # before_action :verify_telegram_webhook!

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

  # def verify_telegram_webhook!
  #   expected_token = Rails.application.credentials.dig(:telegram, :webhook_secret_token).presence || ENV["TELEGRAM_WEBHOOK_SECRET_TOKEN"].presence
  #   if expected_token.present?
  #     received_token = request.headers["X-Telegram-Bot-Api-Secret-Token"].to_s
  #     valid_token = received_token.present? && ActiveSupport::SecurityUtils.secure_compare(received_token, expected_token)
  #     return head :unauthorized unless valid_token
  #   end

  #   update_id = params[:update_id]
  #   return head :bad_request if update_id.blank?

  #   recent_update_ids = self.class.instance_variable_get(:@recent_update_ids) || {}
  #   recent_update_ids.delete_if { |_key, seen_at| seen_at < 1.day.ago }

  #   normalized_update_id = update_id.to_s
  #   return head :conflict if recent_update_ids.key?(normalized_update_id)

  #   recent_update_ids[normalized_update_id] = Time.current
  #   self.class.instance_variable_set(:@recent_update_ids, recent_update_ids)

  #   cache_key = "telegram:webhook:update_id:#{update_id}"
  #   return head :conflict if Rails.cache.exist?(cache_key)

  #   Rails.cache.write(cache_key, true, expires_in: 1.day)
  # end

  def send_telegram_message(chat_id, text)
    bot = Telegram::Bot::Client.new(Rails.application.credentials.dig(:telegram, :bot_token))
    bot.send_message(chat_id: chat_id, text: text)
  rescue => e
    Rails.logger.error("Telegram webhook send error: #{e.message}")
  end
end
