class UserPanel::CorpController < UserPanelController
  before_action :set_stripe_client, only: %i[stripe_new_card stripe_card_success stripe_card_error]

  def landing
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

  def initial_corp_setup
  end

  def save_initial_corp_setup
    @corp.assign_attributes(corp_params)
    @corp.visto = true
    if @corp.save
      redirect_to stripe_new_card_path
    else
      render :initial_corp_setup, status: :unprocessable_entity
    end
  end

  def stripe_new_card
    unless @corp.stripe_customer_id.present?
      customer = @stripe_client.v1.customers.create({ name: @corp.name, email: @corp.email })
      if customer && customer.id
        @corp.update(stripe_customer_id: customer.id)
      else
        return redirect_to user_corp_path, alert: "Error al crear el cliente en Stripe"
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
    redirect_to user_corp_path, alert: "Error al crear la sesión de Stripe"
  end


  def stripe_card_success
    return redirect_to user_corp_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 2" unless params[:session_id].present?

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
        redirect_to user_corp_path, notice: "Tarjeta guardada"
      else
        puts @corp.errors.messages
        redirect_to user_corp_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 0"
      end
    else
      redirect_to user_corp_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 1"
    end

  rescue Stripe::InvalidRequestError => e
    puts e
    redirect_to user_corp_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 3"
  rescue => e
    puts e
    redirect_to user_corp_path, alert: "No se pudo completar el proceso, intenta de nuevo. Error: 4"
  end

  def stripe_card_error
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
      :min_book_amount
    ).to_h
    bh = params.dig(:corp, :business_hours)
    permitted["business_hours"] = bh.to_unsafe_h if bh.present?
    permitted
  end
end
