class UserPanel::CorpController < UserPanelController
  before_action :set_stripe_client, only: %i[stripe_new_card stripe_card_success stripe_card_error]
  skip_before_action :authorize_corp!, only: %i[landing pay_now]

  def landing
    @balance = @corp.balance
  end

  def show
  end

  def edit
  end

  def update
    @corp.assign_attributes(corp_params)
    @corp.visto = true
    if @corp.save
      redirect_to user_corp_path, notice: "Información de empresa actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_spei
    clabe = params[:banco_clabe]
    beneficiario = params[:banco_beneficiario]

    if clabe.blank? || beneficiario.blank?
      return redirect_to user_corp_landing_path, alert: "Todos los campos de SPEI son obligatorios."
    end

    @corp.assign_attributes(banco_clabe: clabe, banco_beneficiario: beneficiario)
    if @corp.save(validate: false)
      redirect_to user_corp_landing_path, notice: "Información de SPEI actualizada exitosamente."
    else
      redirect_to user_corp_landing_path, alert: "Error al actualizar la información de SPEI: #{@corp.errors.full_messages.join(', ')}"
    end
  end

  def retiro_fondos
    puts "--- RETIRO DE FONDOS ---"
    deposits = @corp.deposits.where(status_pago: :pagado, canal: :stripe)
    balance = deposits.sum { |d| d.monto - d.comision_terminal - d.comision_sitio }

    ## deposits_involded ids string
    deposits_involved = deposits.map(&:id).join(",")

    if balance <= 0 or deposits.blank?
      return redirect_to user_corp_landing_path, alert: "No hay fondos disponibles para retiro."
    end

    bill = nil
    line = nil
    bill = Bill.new(
      corp_id: @corp.id,
      tipo: "remision",
      forma_pago: :trasferencia_electronica,
      moneda: "mxn",
      status_pago: "pendiente",
      direccion: :egreso,
      nota_for_corp: "Solicitud de retiro, se verifica manualmente y puede tardar hasta 72 horas hábiles en reflejarse en tu cuenta bancaria.",
      retiro_clabe: @corp.banco_clabe,
      retiro_banco: @corp.banco_nombre,
      retiro_beneficiario: @corp.banco_beneficiario,
      retiro_deposits: deposits_involved
    )
    line =  BillItem.new(
      cantidad: 1,
      nombre: "Retiro de fondos",
      precio: balance,
      descuento: 0,
      iva: 0.0,
      costo: 0.0
    )
    bill.bill_items << line
    if bill.save
      puts "🧾 Bill total: #{bill.total}"
      puts "🧾 Bill line_items: #{bill.bill_items.count}"

      ## limpiamos balance del corp
      deposits.each do |deposit|
        deposit.update(status_pago: :depositado)
      end

      redirect_to user_corp_landing_path, notice: "Solicitud de retiro de fondos creada exitosamente. Se ha generado una factura por $#{bill.total} MXN. Folio: #{bill.folio}"
    else
      puts "🚫 Error al crear Bill: #{bill.errors.full_messages.join(', ')}"
      redirect_to user_corp_landing_path, alert: "Error al crear la solicitud de retiro de fondos: #{bill.errors.full_messages.join(', ')}"

    end
  rescue => e
    puts "🚫 Error inesperado al crear retiro: #{e}"
    redirect_to user_corp_landing_path, alert: "Error inesperado al crear la solicitud de retiro de fondos."
  end

  def initial_corp_setup
  end

  def save_initial_corp_setup
    @corp.assign_attributes(corp_params)
    @corp.visto = true
    if @corp.save
      redirect_to user_panel_home_path, notice: "¡Bienvenido a MiiNegocio, tu cuenta ha sido creada exitosamente!"
    else
      render :initial_corp_setup, status: :unprocessable_entity
    end
  end

  def pay_now
    response = Gtools.do_bill(corp: @corp)

    if response[:success]
      @corp.update(
        status: :activo,
        subscription_updated_at: Time.current,
        subscription_next_billing_date: 30.days.from_now,
        subscription_started_at: @corp.subscription_started_at.present? ? @corp.subscription_started_at : Time.current
      )
      redirect_to user_corp_landing_path, notice: "Pago exitoso. Se ha generado una factura por $#{response[:bill].total} MXN. Folio: #{response[:bill].folio}"
    else
      redirect_to user_corp_landing_path, alert: "Error al procesar el pago: #{response[:response][:error_message]}"
    end
  end

  def stripe_new_card
    unless @corp.stripe_customer_id.present?
      customer = @stripe_client.v1.customers.create({ name: @corp.name, email: @corp.email })
      if customer && customer.id
        @corp.update(stripe_customer_id: customer.id)
      else
        return redirect_to user_corp_landing_path, alert: "Error al crear el cliente en Stripe"
      end
    end


    session = @stripe_client.v1.checkout.sessions.create({
      mode: "setup",
      currency: "mxn",
      customer: @corp.stripe_customer_id,
      success_url: "#{stripe_card_success_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: stripe_card_error_url
    })
    puts "--- session ---"
    puts session
    redirect_to session.url, allow_other_host: true, status: 303
  rescue Stripe::InvalidRequestError => e
    puts e
    redirect_to user_corp_landing_path, alert: "Error al crear la sesión de Stripe"
  end


  def stripe_card_success
    return redirect_to user_corp_landing_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 2" unless params[:session_id].present?

    session = @stripe_client.v1.checkout.sessions.retrieve(params[:session_id])
    set_up = @stripe_client.v1.setup_intents.retrieve(session.setup_intent)

    puts "--- session ---"
    puts session

    puts "--- intent ---"
    puts set_up

    if set_up.status == "succeeded"
      attach_intent = @stripe_client.v1.payment_methods.attach(set_up.payment_method, { customer: @corp.stripe_customer_id })
      @corp.assign_attributes(
        stripe_payment_method_id: set_up.payment_method,
        card_brand: attach_intent.card.brand,
        card_last4: attach_intent.card.last4,
        card_exp_month: attach_intent.card.exp_month,
        card_exp_year: attach_intent.card.exp_year,
        card_country: attach_intent.card.country
      )
      if @corp.save
        redirect_to user_corp_landing_path, notice: "Tarjeta guardada"
      else
        puts @corp.errors.messages
        redirect_to user_corp_landing_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 0"
      end
    else
      redirect_to user_corp_landing_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 1"
    end

  rescue Stripe::InvalidRequestError => e
    puts e
    redirect_to user_corp_landing_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 3"
  rescue => e
    puts e
    redirect_to user_corp_landing_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 4"
  end

  def stripe_card_error
    redirect_to user_corp_landing_path, alert: "Proceso cancelado o error al procesar la tarjeta. Intenta de nuevo."
  end

  def change_plan
    return redirect_to user_corp_landing_path, alert: "Plan no especificado" unless params[:plan].present?
    plan = params[:plan].to_sym
    monto = Setting::PlanPrices.dig(plan, :price)
    if monto.nil?
      return redirect_to user_corp_landing_path, alert: "Plan no válido"
    end

    descuento = @corp.discount
    noww = Time.current

    response = Gtools.do_bill_monto(corp: @corp, monto: monto, descuento: descuento, concepto: "Cambio de plan #{Setting::PlanPrices[plan][:name]}")

    if response[:success]
      @corp.update(
        status: :activo,
        payment_attempts: 0,
        subscription_updated_at: noww,
        subscription_next_billing_date: 30.days.from_now,
        subscription_started_at: @corp.subscription_started_at.present? ? @corp.subscription_started_at : noww,
        tipo_plan: plan
      )
      redirect_to user_corp_landing_path, notice: "Plan cambiado exitosamente a #{Setting::PlanPrices[plan][:name]}. Se ha generado una factura por $#{response[:bill].total} MXN. Folio: #{response[:bill].folio}"
    else
      redirect_to user_corp_landing_path, alert: "Error al procesar el cambio de plan: #{response[:response][:error_message]}"
    end
  end

  def charge_sms
    return redirect_to user_corp_landing_path, alert: "Cantidad no especificada" unless params[:cantidad].present?
    key = params[:cantidad].to_i
    monto = Setting::SmsPrices.dig(key, :price)

    if monto.nil?
      return redirect_to user_corp_landing_path, alert: "Cantidad no válida"
    end

    response = Gtools.do_bill_monto(corp: @corp, monto: monto, concepto: "Compra de #{Setting::SmsPrices[key][:name]}")

    if response[:success]
      @corp.increment!(:sms, key)
      redirect_to user_corp_landing_path, notice: "Compra de #{Setting::SmsPrices[key][:name]} exitosa. Se ha generado una factura por $#{response[:bill].total} MXN. Folio: #{response[:bill].folio}"
    else
      redirect_to user_corp_landing_path, alert: "Error al procesar la compra de SMS: #{response[:response][:error_message]}"
    end
  end

  def charge_timbres
    return redirect_to user_corp_landing_path, alert: "Cantidad no especificada" unless params[:cantidad].present?
    key = params[:cantidad].to_i
    monto = Setting::TimbrePrices.dig(key, :price)
    if monto.nil?
      return redirect_to user_corp_landing_path, alert: "Cantidad no válida"
    end

    response = Gtools.do_bill_monto(corp: @corp, monto: monto, concepto: "Compra de #{Setting::TimbrePrices[key][:name]}")

    if response[:success]
      @corp.increment!(:timbres, key)
      redirect_to user_corp_landing_path, notice: "Compra de #{Setting::TimbrePrices[key][:name]} exitosa. Se ha generado una factura por $#{response[:bill].total} MXN. Folio: #{response[:bill].folio}"
    else
      redirect_to user_corp_landing_path, alert: "Error al procesar la compra de timbres: #{response[:response][:error_message]}"
    end
  end

  private

  def set_stripe_client
    @stripe_client = Stripe::StripeClient.new(Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :secret_key))
  end

  def corp_params
    permitted = params.require(:corp).permit(
      :calendar,
      :calle,
      :ciudad,
      :colonia,
      :cp,
      :estado,
      :facebook_url,
      :instagram_url,
      :key_pass,
      :localidad,
      :name,
      :num_ext,
      :num_int,
      :online_payments,
      :phone,
      :tel_prefix,
      :public_site,
      :razon,
      :regimen,
      :rfc,
      :text_cotizacion,
      :text_factura,
      :text_remision,
      :tiktok_url,
      :timbres,
      :tipo_negocio,
      :whatsapp,
      :facturacion,
      :key,
      :cer,
      :logo,
      :email,
      :public_calendar,
      :min_book_amount,
      :banco_clabe,
      :banco_beneficiario
    ).to_h
    bh = params.dig(:corp, :business_hours)
    permitted["business_hours"] = bh.to_unsafe_h if bh.present?
    permitted
  end
end
