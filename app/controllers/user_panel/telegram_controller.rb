# Handles Telegram Login Widget callback (OAuth-style) and linking/unlinking
class UserPanel::TelegramController < UserPanelController
  skip_before_action :verify_authenticity_token, only: :callback

  # GET /panel/telegram/callback
  # Telegram Login Widget redirects here after auth
  def callback
    unless valid_telegram_hash?(params)
      return redirect_to user_corp_landing_path, alert: "Error de verificación de Telegram"
    end

    telegram_id = params[:id].to_i
    if telegram_id.zero?
      return redirect_to user_corp_landing_path, alert: "No se recibió el ID de Telegram"
    end

    if Corp.where.not(id: @corp.id).exists?(telegram_id: telegram_id)
      return redirect_to user_corp_landing_path, alert: "Esta cuenta de Telegram ya está vinculada a otro negocio."
    end

    @corp.update!(telegram_id: telegram_id, telegram_linked_at: Time.current)
    redirect_to user_corp_landing_path, notice: "✅ Telegram vinculado exitosamente"
  end

  # DELETE /panel/telegram/unlink
  def unlink
    @corp.update!(telegram_id: nil, telegram_linked_at: nil)
    redirect_to user_corp_landing_path, notice: "Telegram desvinculado"
  end

  # GET /panel/corp/telegram_link
  def telegram_link
    @token = SecureRandom.urlsafe_base64(16)
    @corp.update!(telegram_link_token: @token)

    @bot_username = Rails.application.credentials.dig(:telegram, :bot_username)
    @deep_link = "https://t.me/#{@bot_username}?start=#{@token}"
  end

  private

  # Verifies data came from Telegram (Telegram Login Widget docs)
  # https://core.telegram.org/widgets/login#checking-authorization
  def valid_telegram_hash?(params)
    received_hash = params[:hash]
    return false if received_hash.blank?

    # Build the data-check-string from all fields except :hash
    data_check = params.to_unsafe_h
      .except(:hash, :controller, :action)
      .sort
      .map { |k, v| "#{k}=#{v}" }
      .join("\n")

    # Compute HMAC-SHA-256 using bot token as key
    bot_token = Rails.application.credentials.dig(:telegram, :bot_token)
    secret = OpenSSL::Digest::SHA256.digest(bot_token)
    computed_hash = OpenSSL::HMAC.hexdigest("SHA256", secret, data_check)

    ActiveSupport::SecurityUtils.secure_compare(computed_hash, received_hash)
  end
end
