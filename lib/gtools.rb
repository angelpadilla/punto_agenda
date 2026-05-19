module Gtools
    def self.update_dolar
        url = "https://www.banxico.org.mx/SieAPIRest/service/v1/series/SF43718/datos/oportuno"
        res = HTTP.headers('Content-Type': "application/json; charset=utf-8", 'Bmx-Token': Rails.application.credentials.dig(:banxico_token)).get(url)

        # "idSerie": "SF43718"
        # puts res.to_s

        if res.status.success?
        body = res.to_s.empty? ? {} : JSON.parse(res.to_s)["bmx"]["series"][0]["datos"][0]
        { success: true, body: { fecha: body["fecha"], precio: body["dato"].to_f } }
        else
        { success: false, body: "#{res.status.reason}, status: #{res.status}" }
        end
    rescue HTTP::ConnectionError => e
        { success: false, body: e }
    end

    def self.telegram_noti(message:)
        message = message.to_s
        puts "---- Notificando al admin por Telegram"

        bot = Telegram::Bot::Client.new(Rails.application.credentials.dig(:telegram, :bot_token))
        bot.send_message(chat_id: Rails.application.credentials.dig(:telegram, :admin_id), text: message)
    rescue Telegram::Bot::Error => e
        puts "--- Telegram error: #{e}"
    end
end
