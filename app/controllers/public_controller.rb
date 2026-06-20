class PublicController < ApplicationController
  before_action :find_corp_by_sku, only: [ :show_corp, :show_corp_calendar, :show_corp_menu, :book_event, :new_booking ]

  def home
    @last_articles = Post.default.limit(6)
  end

  def index_blog
    posts = Post.default

    @q = posts.ransack(params[:q])
    @pagy, @posts = pagy(@q.result(distinct: true), limit: 6)
  end

  def show_blog
    @post = Post.find_by(slug: params[:slug])
    redirect_to index_blog_path, alert: "Artículo no encontrado" unless @post
  end


  def html_elements
  end

  def ticket80
    @order = Order.includes(:customer, :line_items, :corp).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order

    pdf = Order80Pdf.new(order: @order)
    send_data pdf.render, filename: "venta_#{@order.folio}.pdf", type: "application/pdf", disposition: "inline"
  end

  def ticket
    @order = Order.includes(:customer, :line_items, :corp).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order

    pdf = OrderPdf.new(order: @order)
    send_data pdf.render, filename: "venta_#{@order.folio}.pdf", type: "application/pdf", disposition: "inline"
  end

  def ticket_xml
    @order = Order.find_by(folio: params[:folio])
    redirect_to root_path, alert: "Order not found" if !@order
    send_data @order.xml, filename: "venta_#{@order.folio}.xml", disposition: "attachment"
  end

  def pdf_abono
    @deposit = Deposit.includes(:depositable).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit

    pdf = AbonoPdf.new(deposit: @deposit)
    send_data pdf.render, filename: "abono_#{@deposit.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  def ticket_abono
    @deposit = Deposit.includes(:depositable).find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit
    pdf = Abono80Pdf.new(deposit: @deposit)
    send_data pdf.render, filename: "abono_#{@deposit.id}.pdf", type: "application/pdf", disposition: "inline"
  end

  def abono_xml
    @deposit = Deposit.find_by(folio: params[:folio])
    redirect_to root_path, alert: "Abono no encontrado" if !@deposit
    send_data @deposit.xml, filename: "abono_#{@deposit.id}.xml", disposition: "attachment"
  end

  # --- Páginas públicas de empresa ---

  def show_corp
    redirect_to root_path, alert: "Empresa no encontrada" unless @corp
  end

  def show_corp_calendar
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" unless @corp.public_calendar
    @items = @corp.items.servicio.activo
    @calendar_data = generate_available_slots
  end

  def new_booking
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" unless @corp.public_calendar

    @dia  = Date.parse(params[:dia]) rescue nil
    @slot = params[:slot].to_s
    @user = @corp.users.find_by(id: params[:user_id]) if params[:user_id].present?

    unless @dia && @slot.present? && @user
      return redirect_to corp_calendar_path(@corp.sku), alert: "Selecciona un horario y un agente"
    end

    # Formato AM/PM para mostrar (el hidden field mantiene 24h para book_event)
    if @slot.include?("|")
      parts = @slot.split("|")
      @slot_display = parts.map { |t| Time.zone.parse("#{@dia} #{t}").strftime("%I:%M %p") }.join(" – ")
    end

    @items = @corp.items.servicio.activo
  end

  def show_corp_menu
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El catálogo no está disponible" unless @corp.public_site
    @cate_filter = params[:cate]
    @items = @corp.items.activo.includes(:brand).order(:cate, :name)
    @items = @items.where(cate: @cate_filter) if @cate_filter.present?
  end

  def book_event
    return redirect_to root_path, alert: "Empresa no encontrada" unless @corp
    return redirect_to corp_home_path(@corp.sku), alert: "El calendario no está disponible" unless @corp.public_calendar

    # validar parametros requeridos
    unless params[:dia].present? && params[:slot].present? && params[:user_id].present?
      return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: "Parametros incompletos"
    end

    unless params[:email].present? && params[:nombre].present? && params[:tel].present? && params[:tel_prefix].present?
      return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: "Completa todos los campos requeridos"
    end

    # Accept both ISO8601 ("2026-06-18T09:00:00-06:00") and range ("09:00|11:00") formats
    slot_param = params[:slot].to_s.strip
    if slot_param.include?("|")
      dia = Date.parse(params[:dia]) rescue nil
      open_time = slot_param.split("|").first
      slot = dia ? Time.zone.parse("#{dia} #{open_time}") : nil
    else
      slot = Time.zone.parse(slot_param) rescue nil
    end

    unless slot
      return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: "Selecciona un horario válido"
    end

    customer = Customer.find_by(email: params[:email].to_s.strip.downcase)
    if customer.nil?
      token = Generatepass.gen(exclude_ambiguous: true, include_symbols: false, length: 8)
      customer = Customer.new(
        email:      params[:email].to_s.strip.downcase,
        razon:      params[:nombre].to_s.strip,
        tel:        params[:tel].to_s.strip,
        tel_prefix: params[:tel_prefix].presence || "+52",
        canal:      :web,
        password:   token,
        password_confirmation: token,
        passs: token
      )
      unless customer.save
        return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: customer.errors.full_messages.first
      end
    end
    CorpCustomer.find_or_create_by(corp: @corp, customer: customer)



    user = @corp.users.find_by(id: params[:user_id]) || @corp.users.first
    unless user
      return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: "No hay agentes disponibles en este momento"
    end

    hora_inicio = slot
    day_config  = @corp.business_hours[slot.wday.to_s]
    slot_range  = (day_config&.dig("hours") || []).find { |r| Time.zone.parse("#{slot.to_date} #{r['open']}") == slot }
    hora_final  = slot_range ? Time.zone.parse("#{slot.to_date} #{slot_range['close']}") : slot + 60.minutes

    necesita_pago_online = @corp.online_payments && @corp.min_book_amount > 0

    event = Event.new(
      corp:        @corp,
      customer:    customer,
      user:        user,
      title:       params[:servicio].presence || "Cita desde web",
      body:        params[:notas],
      hora_inicio: hora_inicio,
      hora_final:  hora_final,
      canal:       :web,
      status:      necesita_pago_online ? :pendiente_pago : :por_confirmar
    )

    if event.save
      # si la empresa tiene activados los pagos en línea y el monto mínimo para reservar es mayor a 0, tenemos que dirigir
      # al proceso de pago y crear orden y depósito correspondiente, de lo contrario solo notificamos al cliente y al admin y esperamos a que el cliente pague en físico y el admin confirme la cita manualmente
      # 1 - revisar stripe_customer_id
      # 2 - crear sesión de pago con monto mínimo, concepto "Reserva de cita", metadata con corp_id y customer_id y guardar el  stripe_payment_method_id en el cliente para futuras compras

      if necesita_pago_online

        if !customer.stripe_customer_id.present?
          response = customer.create_stripe_customer
          unless response[:success]
            return redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: respose[:message]
          end
        end
        customer.reload

        do_order_monto(corp: @corp, event: event, customer: customer, user: user, monto: @corp.min_book_amount, concepto: "Reserva de cita - #{event.title}")

      else
        # si no se necesita pago en línea, simplemente esperamos a que el cliente pague en fisico
        # y confirmacion manual de la cita por parte del admin
        EventMailer.with(corp: @corp, event: event).noti_corp.deliver_later
        redirect_to corp_home_path(@corp.sku), notice: "¡Cita agendada! Por favor espera la confirmación al email que proporcionaste."
      end

    else
      redirect_back fallback_location: corp_calendar_path(@corp.sku), alert: event.errors.full_messages.join(", ")
    end
  end

  def book_payment_success
    # "/e/reservar/success?customer_id=6&deposit_id=9&event_folio=H7GKWZV&order_folio=JoqilIKPZ&sku=FZQRU?session_id=cs_test_a17vy3RspZq7LufNwKtDYqSouZi1svXzHcGHNnA7HPqs9X6OTfiIWxdubb"
    # validaciones
    puts "--- ✅✅✅✅ book_payment_success ---"
    unless params[:session_id].present? and params[:event_folio].present? and params[:order_folio].present? and params[:sku].present? and params[:deposit_id].present? and params[:customer_id].present?
      return redirect_to root_path, alert: "Parametros incompletos"
    end

    @corp = Corp.find_by(sku: params[:sku])
    @event = Event.find_by(folio: params[:event_folio])
    @order = Order.find_by(folio: params[:order_folio])
    @deposit = Deposit.find_by(id: params[:deposit_id])
    @customer = Customer.find_by(id: params[:customer_id])

    if @corp.nil? || @event.nil? || @order.nil? || @deposit.nil? || @customer.nil?
      return redirect_to root_path, alert: "Datos no encontrados"
    end

    @stripe_client = set_stripe_client
    session  = @stripe_client.v1.checkout.sessions.retrieve(params[:session_id])
    @payment_intent = @stripe_client.v1.payment_intents.retrieve(session.payment_intent)

    puts "🧾🧾🧾🧾🧾🧾 Respuesta de Stripe en success callback: "
    puts @payment_intent
    puts "------------------------------------------------"

    if @payment_intent.status == "succeeded"
      payment_method_id = @payment_intent.payment_method
      payment_method = @stripe_client.v1.payment_methods.retrieve(payment_method_id)

      puts "🧾🧾🧾🧾🧾🧾 Respuesta de Stripe en success callback - Payment Method: "
      puts payment_method
      puts "------------------------------------------------"

      card_country_before = @customer.card_country

      @customer.update(
        stripe_payment_method_id: payment_method_id,
        card_brand: payment_method.card.brand,
        card_last4: payment_method.card.last4,
        card_exp_month: payment_method.card.exp_month,
        card_exp_year: payment_method.card.exp_year,
        card_country: payment_method.card.country
      )

      ## verificar una vez mas las comisiones por si el usuario pago con una tarjeta internacional

      monto_para_corp_antes = @order.total - (@deposit.comision_sitio + @deposit.comision_terminal)
      puts "🔎 Comisiones antes de actualizar: "
      puts "Comision app: #{@deposit.comision_sitio}, Comisión terminal: #{@deposit.comision_terminal}, Comisión total: #{@deposit.comision_sitio + @deposit.comision_terminal},,,, Order ganancia: #{@order.ganancia}"
      puts "Monto para corp antes de actualizar: #{monto_para_corp_antes}"

      internacional_changed = card_country_before != @customer.card_country
      if internacional_changed
        puts "🔎🔎🔎 El pago fue realizado con una tarjeta internacional, actualizando comisiones..."
        comision_total, stripe_fee, comision_app = Gtools.comision_minegocio(@order.total, internacional: internacional_changed).values_at(:comision_total, :stripe_fee, :comision_app)

        @deposit.update(comision_terminal: stripe_fee, comision_sitio: comision_app)
        @order.save

        monto_para_corp_despues = @order.total - (@deposit.comision_sitio + @deposit.comision_terminal)

        puts "🔎🔎🔎 Comisiones después de actualizar: "
        puts "Comision app: #{@deposit.comision_sitio}, Comisión terminal: #{@deposit.comision_terminal}, Comisión total: #{@deposit.comision_sitio + @deposit.comision_terminal},,,, Order ganancia: #{@order.ganancia}"
        puts "Monto para corp después de actualizar: #{monto_para_corp_despues}"
      end

    else
      redirect_to corp_calendar_path(@corp.sku), alert: "El pago no se completó exitosamente. Status: #{@payment_intent.status}"
    end
  end

  def book_payment_error
    # validaciones
    unless params[:session_id].present? and params[:event_folio].present? and params[:order_folio].present? and params[:sku].present? and params[:deposit_id].present? and params[:customer_id].present?
      return redirect_to root_path, alert: "Parametros incompletos"
    end

    @corp = Corp.find_by(sku: params[:sku])
    @event = Event.find_by(folio: params[:event_folio])
    @order = Order.find_by(folio: params[:order_folio])
    @deposit = Deposit.find_by(id: params[:deposit_id])
    @customer = Customer.find_by(id: params[:customer_id])

    if @corp.nil? || @event.nil? || @order.nil? || @deposit.nil? || @customer.nil?
      return redirect_to root_path, alert: "Datos no encontrados"
    end

    @stripe_client = set_stripe_client
    session  = @stripe_client.v1.checkout.sessions.retrieve(params[:session_id])
    @payment_intent = @stripe_client.v1.payment_intents.retrieve(session.payment_intent)
  end

  private

  def find_corp_by_sku
    @corp = Corp.find_by(sku: params[:sku])
  end

  def generate_available_slots
    return {} unless @corp.business_hours.present?
    return {} if @corp.users.empty?

    # simple_calendar envía ?start_date= al navegar entre semanas
    week_start = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current
    # Solo los días de la semana mostrada (7 en desktop, 3 en mobile — cubrimos 7)
    window_end = week_start + 6

    result = {}
    (week_start..window_end).each do |date|
      info = @corp.available_slots_for_day(date)
      result[date] = info if info
    end
    result
  end

  def set_stripe_client
    Stripe::StripeClient.new(Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key))
  end

  def stripe_payment(amount:, corp:, customer:, desc:, event_folio:, order_folio:, deposit_id:, customer_id:)
    # intento de pago especial, aqui no tenemos aun los datos de tarjeta del cliente,
    # los datos de tarjeta se capturan en el success despues de la pantalla de pago por stripe
    stripe_client = Stripe::StripeClient.new(Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key))
    payment_intent = stripe_client.v1.checkout.sessions.create({
      mode: "payment",
      currency: "mxn",
      customer: customer.stripe_customer_id,
      line_items: [ {
        price_data: {
          currency: "mxn",
          product_data: {
            name: desc
          },
          unit_amount: (amount * 100).to_i
        },
        quantity: 1
      } ],
      metadata: {
        corp_id: corp.id,
        customer_id: customer.id,
        event_folio: event_folio,
        order_folio: order_folio
      },
      success_url: "#{corp_book_payment_success_url(sku: @corp.sku, event_folio: event_folio, order_folio: order_folio, deposit_id: deposit_id, customer_id: customer_id)}&session_id={CHECKOUT_SESSION_ID}",
      cancel_url: corp_book_payment_error_url(sku: @corp.sku, event_folio: event_folio, order_folio: order_folio, deposit_id: deposit_id, customer_id: customer_id)
    })
    # redirect_to payment_intent.url, allow_other_host: true, status: 303
    puts "🧾🧾🧾🧾🧾🧾 Respuesta de Stripe: "
    puts payment_intent
    puts "------------------------------------------------"
    if payment_intent.status == "open"
      puts "✅ Pago Stripe exitoso para Corp #{corp.id}, Monto: #{amount}"
      {
        success: true,
        status: payment_intent.status,
        error: nil,
        error_message: nil,
        body: payment_intent,
        url: payment_intent.url
      }
    else
      puts "❌ Pago Stripe no exitoso para Corp #{corp.id}, Status: #{payment_intent.status}"
      {
        success: false,
        status: payment_intent.status,
        error: payment_intent.error ? payment_intent.error : nil,
        error_message: payment_intent.error ? payment_intent.error.message : nil,
        body: payment_intent,
        url: payment_intent.url
      }
    end
  rescue Stripe::CardError => e
    puts "🚫 Error de tarjeta al procesar pago Stripe: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil, url: nil }
  rescue Stripe::StripeError => e
    puts "🚫 Error de Stripe al procesar pago: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil, url: nil }
  rescue => e
    puts "🚫 Error inesperado al procesar pago Stripe: #{e}"
    { success: false, status: nil,  error: e, error_message: e.message, body: nil, url: nil }
  end

  def do_order_monto(corp:, event:, customer:, user:, monto:, concepto:)
    nowww = Time.current
    noww = nowww.strftime("%d %b %I:%M %p")
    order = nil
    line = nil
    deposit = nil
    # miinegocio cobra una comsion del total del 5% (comision combinada de stripe + comision remanente para mii negocio)
    # comision_terminal = self.stripe_fee(monto, internacional: corp.card_country.present? && corp.card_country != "MX")
    comision_total, stripe_fee, comision_app = Gtools.comision_minegocio(monto).values_at(:comision_total, :stripe_fee, :comision_app)


    ActiveRecord::Base.transaction do
      order = Order.new(
        user_id: user.id,
        seller_id: user.id,
        customer_id: customer.id,
        event_id: event.id,
        corp_id: corp.id,
        tipo: "remision",
        forma_pago: :tarjeta_de_debito,
        status_pago: "pendiente",
        fecha: nowww,
      )
      line =  LineItem.new(
        cantidad: 1,
        precio: monto,
        iva: 16.0,
        name: concepto
      )
      deposit = Deposit.new(
        monto: monto,
        forma_pago: :tarjeta_de_debito,
        tipo: :ingreso,
        created_at: nowww,
        comision_terminal: stripe_fee,
        comision_sitio: comision_app,
        status_pago: :pendiente,
        canal: :stripe
      )
      order.line_items << line
      order.deposits << deposit
      order.save!
    end

    puts "🧾 Order total: #{order.total}"
    puts "🧾 Order comision_terminal: #{order.comision_terminal}"
    puts "🧾 Order comision_sitio: #{order.comision_sitio}"
    puts "🧾 Order line_items: #{order.line_items.count}"

    response = stripe_payment(amount: monto, corp: corp, customer: customer, desc: "#{concepto}, order ID: #{order.id}", event_folio: event.folio, order_folio: order.folio, deposit_id: deposit.id, customer_id: customer.id)

    if response[:success]

      order.update!(status_pago: :pagado)
      deposit.update!(status_pago: :pagado, stripe_payment_id: response[:body].id)
      event.update!(status: :agendado)
      EventMailer.with(corp: corp, event: event).noti_corp.deliver_later
      Gtools.telegram_noti(message: "MiiNegocio \nStripe pago exitoso de reserva online:\n Monto: #{order.total} MXN\n Corp ID: #{corp.id}\n Order ID: #{order.id}\n Fecha: #{Time.current.strftime("%d %b %I:%M %p")}")
      puts "🧾 Order creada para Corp #{corp.id} con pago Stripe exitoso"

      # { success: true, order: order, deposit: deposit, response: response }
      redirect_to response[:url], allow_other_host: true, status: 303
    else
      order.update(status_pago: :cancelado)
      deposit.update(status_pago: :error_pago, error: response[:error_message])
      event.update(status: :cancelado, motivo_cancelacion: "Error en pago en línea")
      order.update(error: "Error al procesar pago Stripe: #{response[:error_message]}")
      puts "🚫 No se pudo completar order para Corp #{corp.id} debido a error en pago Stripe: #{response[:error_message]}"

      redirect_to corp_calendar_path(corp.sku), alert: "No se pudo completar la reserva debido a un error en el pago: #{response[:error_message]}"
    end

  rescue ActiveRecord::RecordInvalid => e
    puts "🚫 Error al crear Order/LineItem: #{e.record.errors.full_messages.join(', ')}"
  rescue => e
    puts "🚫 Error inesperado al crear order: #{e}"
    order.destroy if order
    event.destroy if event
  end
end
