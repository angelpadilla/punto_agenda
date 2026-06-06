module Gtools
  STRIPE_RATE_NACIONAL      = 0.036
  STRIPE_RATE_INTERNACIONAL = 0.041  # +0.5% tarjeta internacional
  STRIPE_FIXED_FEE          = 3.00
  STRIPE_TAX                = 0.16   # IVA sobre la comisión

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

  ## Cobranza mensual de suscripciones, se ejecuta cada dia por un active job (CobranzaJob) o un rake task (corps:cobranza)
  def self.cobranza
    corps = Corp.get_corps_cobranza
    noww = Time.current
    corps.find_each do |corp|
      puts "Procesando cobranza para Corp ID: #{corp.id}, Nombre: #{corp.name}"
      result = self.do_bill(corp: corp)
      if result[:success]
        corp.update(
          status: :activo,
          payment_attempts: 0,
          subscription_updated_at: noww,
          subscription_next_billing_date: 30.days.from_now,
          subscription_started_at: corp.subscription_started_at.present? ? corp.subscription_started_at : noww
        )
        CobranzaMailer.with(corp: corp, bill: result[:bill]).success_payment.deliver_later
        puts "✅ Cobranza exitosa para Corp ID: #{corp.id}, Bill ID: #{result[:bill].id}"
      else
        if corp.payment_attempts >= 10
          corp.update(
            status: :suspendido,
            subscription_updated_at: noww,
          )
          CobranzaMailer.with(corp: corp, bill: result[:bill]).suspendido.deliver_later
          puts "⚠️ Corp ID: #{corp.id} suspendido por superar intentos de pago fallidos"
        else
          corp.update(
            status: :moroso,
            subscription_updated_at: noww,
            payment_attempts: corp.payment_attempts + 1
          )
          CobranzaMailer.with(corp: corp, bill: result[:bill]).failed_payment.deliver_later
          puts "⚠️ Cobranza fallida para Corp ID: #{corp.id}, Bill ID: #{result[:bill] ? result[:bill].id : 'N/A'}, Intentos de pago fallidos: #{corp.payment_attempts}"
        end
      end
    rescue => e
      puts "🚫 RescueError en loop, procesando cobranza para Corp ID: #{corp.id}: #{e.message}"
    end
  rescue => e
    puts "🚫 RescueError al iniciar cobranza: #{e.message}"
  end

  def self.telegram_noti(message:)
    message = message.to_s
    puts "💬 Notificando al admin por Telegram"

    bot = Telegram::Bot::Client.new(Rails.application.credentials.dig(:telegram, :bot_token))
    bot.send_message(chat_id: Rails.application.credentials.dig(:telegram, :admin_id), text: message)
  rescue Telegram::Bot::Error => e
    puts "🚫 Telegram error: #{e}"
  end

  def self.stripe_fee(monto, internacional: false)
    rate = internacional ? STRIPE_RATE_INTERNACIONAL : STRIPE_RATE_NACIONAL
    base = monto * rate + STRIPE_FIXED_FEE
    (base * (1 + STRIPE_TAX)).round(2)
  end

  def self.do_dummy_bill(corp_id:)
    corp = Corp.find(corp_id)
    noww = Time.current.strftime("%d %b %I:%M %p")
    monto = Setting::PlanPrices[corp.tipo_plan.to_sym][:price]
    descuento = corp.discount
    bill = nil
    line = nil
    internacional = corp.card_country.present? && corp.card_country != "MX"
    ActiveRecord::Base.transaction do
      bill = Bill.new(
        corp_id: corp_id,
        tipo: "remision",
        forma_pago: :tarjeta_de_debito,
        moneda: "mxn",
        status_pago: "pendiente",
      )
      line =  BillItem.new(
        cantidad: 1,
        nombre: "Servicio de prueba",
        precio: monto,
        descuento: descuento,
        iva: 16.0,
        costo: self.stripe_fee(monto, internacional: internacional)
      )
      bill.bill_items << line
      bill.save
    end

    puts "🧾 Bill total: #{bill.total}"
    puts "🧾 Bill line_items: #{bill.bill_items.count}"
    puts "🧾 Bill ID: #{bill.id}, Folio: #{bill.folio}"

    response = self.stripe_payment(amount: bill.total, corp: corp, desc: "Pago de prueba para remision dummy fecha: #{noww}, folio: #{bill.folio}", folio: bill.folio)
    if response[:success]
      bill.update(status_pago: "pagado", stripe_payment_id: response[:body].id)
      self.telegram_noti(message: "Creando remision de prueba para Corp #{corp_id}, folio: #{bill.folio}, fecha: #{noww}")
      puts "🧾 remision dummy creada para Corp #{corp_id} con pago Stripe exitoso"
    else
      bill.update(status_pago: "error_pago", error: response[:error_message], nota_for_corp: "Error al procesar pago Stripe: #{response[:error_message]}")
      line.update(error: response[:error_message])
      puts "🚫 No se pudo crear remision dummy para Corp #{corp_id} debido a error en pago Stripe: #{response[:error_message]}"
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "🚫 Error al crear Bill/BillItem: #{e.record.errors.full_messages.join(', ')}"
  rescue ActiveRecord::RecordNotFound => e
    puts "🚫 Corp no encontrado para remision dummy: #{e}"
  rescue => e
    puts "🚫 Error inesperado al crear remision dummy: #{e}"
  end

  def self.stripe_payment(amount:, corp:, desc: nil, folio: nil)
    # unless corp && corp.stripe_customer_id && corp.stripe_payment_method_id
    #   puts "🚫 Corp sin métodos de pago para pago Stripe: #{corp.id}"
    #   return
    # end

    stripe_client = Stripe::StripeClient.new(Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key))
    unless corp.stripe_customer_id.present?
      customer = stripe_client.v1.customers.create({
        name: corp.name,
        email: corp.email
      })
      corp.update(stripe_customer_id: customer.id)
    end

    unless corp.stripe_payment_method_id.present?
      puts "🚫 Corp sin método de pago para pago Stripe: #{corp.id}"
      return { success: false, status: nil, error: "Corp sin método de pago para pago Stripe", error_message: "Corp sin método de pago para pago Stripe", body: nil }
    end

    payment_intent = stripe_client.v1.payment_intents.create({
      amount: (amount * 100).to_i,
      currency: "mxn",
      customer: corp.stripe_customer_id,
      payment_method: corp.stripe_payment_method_id,
      off_session: true,
      confirm: true,
      description: desc,
      metadata: { corp_id: corp.id, amount: amount, folio: folio ? folio : nil }
    })

    if payment_intent.status == "succeeded"
      puts "✅ Pago Stripe exitoso para Corp #{corp.id}, Monto: #{amount}"
      {
        success: true,
        status: payment_intent.status,
        error: nil,
        error_message: nil,
        body: payment_intent
      }
    else
      puts "❌ Pago Stripe no exitoso para Corp #{corp.id}, Status: #{payment_intent.status}"
      {
        success: false,
        status: payment_intent.status,
        error: payment_intent.error ? payment_intent.error : nil,
        error_message: payment_intent.error ? payment_intent.error.message : nil,
        body: payment_intent
      }
    end
  rescue Stripe::CardError => e
    puts "🚫 Error de tarjeta al procesar pago Stripe: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil }
  rescue Stripe::StripeError => e
    puts "🚫 Error de Stripe al procesar pago: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil }
  rescue => e
    puts "🚫 Error inesperado al procesar pago Stripe: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil }
  end


  def self.do_bill(corp:)
    noww = Time.current.strftime("%d %b %I:%M %p")
    monto = Setting::PlanPrices[corp.tipo_plan.to_sym][:price]
    descuento = corp.discount
    bill = nil
    line = nil
    internacional = corp.card_country.present? && corp.card_country != "MX"
    ActiveRecord::Base.transaction do
      bill = Bill.new(
        corp_id: corp.id,
        tipo: "remision",
        forma_pago: :tarjeta_de_debito,
        moneda: "mxn",
        status_pago: "pendiente",
      )
      line =  BillItem.new(
        cantidad: 1,
        nombre: "Suscripción #{corp.tipo_plan.titleize}",
        precio: monto,
        descuento: descuento,
        iva: 16.0,
        costo: self.stripe_fee(monto, internacional: internacional)
      )
      bill.bill_items << line
      bill.save
    end

    puts "🧾 Bill total: #{bill.total}"
    puts "🧾 Bill line_items: #{bill.bill_items.count}"

    response = self.stripe_payment(amount: bill.total, corp: corp, desc: "Suscripción #{corp.tipo_plan.titleize} fecha: #{noww}, folio: #{bill.folio}", folio: bill.folio)
    if response[:success]
      bill.update(status_pago: "pagado", stripe_payment_id: response[:body].id)
      self.telegram_noti(message: "MiiNegocio \nPago exitoso de:\n Monto: #{bill.total} MXN\n Corp ID: #{corp.id}\n Folio: #{bill.folio}\n Fecha: #{noww}")
      puts "🧾 remision creada para Corp #{corp.id} con pago Stripe exitoso"
      return { success: true, bill: bill, response: response }
    else
      bill.update(status_pago: "error_pago", error: response[:error_message], nota_for_corp: "Error al procesar pago con tu tarjeta: #{response[:error_message]}")
      line.update(error: response[:error_message])
      puts "🚫 No se pudo crear remision para Corp #{corp.id} debido a error en pago Stripe: #{response[:error_message]}"
      return { success: false, bill: bill, response: response }
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "🚫 Error al crear Bill/BillItem: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    puts "🚫 Error inesperado al crear remision: #{e}"
  end

  def self.do_bill_monto(corp:, monto:, concepto:, descuento: 0.0)
    noww = Time.current.strftime("%d %b %I:%M %p")
    monto = monto.to_f
    descuento = descuento.to_f
    bill = nil
    line = nil
    internacional = corp.card_country.present? && corp.card_country != "MX"
    ActiveRecord::Base.transaction do
      bill = Bill.new(
        corp_id: corp.id,
        tipo: "remision",
        forma_pago: :tarjeta_de_debito,
        moneda: "mxn",
        status_pago: "pendiente",
      )
      line =  BillItem.new(
        cantidad: 1,
        nombre: concepto,
        precio: monto,
        descuento: descuento,
        iva: 16.0,
        costo: self.stripe_fee(monto, internacional: internacional)
      )
      bill.bill_items << line
      bill.save
    end

    puts "🧾 Bill total: #{bill.total}"
    puts "🧾 Bill line_items: #{bill.bill_items.count}"

    response = self.stripe_payment(amount: bill.total, corp: corp, desc: "#{concepto} fecha: #{noww}, folio: #{bill.folio}", folio: bill.folio)
    if response[:success]
      bill.update(status_pago: "pagado", stripe_payment_id: response[:body].id)
      self.telegram_noti(message: "MiiNegocio \nPago exitoso de:\n Monto: #{bill.total} MXN\n Corp ID: #{corp.id}\n Folio: #{bill.folio}\n Fecha: #{noww}")
      puts "🧾 Remision creada para Corp #{corp.id} con pago Stripe exitoso"
      return { success: true, bill: bill, response: response }
    else
      bill.update(status_pago: "error_pago", error: response[:error_message], nota_for_corp: "Error al procesar pago Stripe: #{response[:error_message]}")
      line.update(error: response[:error_message])
      puts "🚫 No se pudo crear remision para Corp #{corp.id} debido a error en pago Stripe: #{response[:error_message]}"
      return { success: false, bill: bill, response: response }
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "🚫 Error al crear Bill/BillItem: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    puts "🚫 Error inesperado al crear remision: #{e}"
  end
end
